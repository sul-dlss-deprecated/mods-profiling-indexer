# external gems
require 'confstruct'

require 'profiler/solr_doc_builder'
require 'gdor/indexer'
require 'solrizer'

# Base class to harvest from DOR via harvestdor gem
class Indexer < GDor::Indexer

  # Initialize with configuration files
  # @param yml_path [String] /path/to
  # @param options [Hash]
  def initialize(*args)
    options = args.extract_options!
    yml_path = args.first

    @success_count = 0
    @error_count = 0
    @total_time_to_solr = 0
    @total_time_to_parse = 0
    @retries = 0
    @druids_failed_to_ix = []
    @validation_messages = StringIO.new
    @config ||= Confstruct::Configuration.new options
    @config.configure(YAML.load_file(yml_path)) if yml_path && File.exist?(yml_path)
    config.configure options
    yield @config if block_given?
    @harvestdor = Harvestdor::Indexer.new @config
  end

  def logger
    config_level =
      case config.log_level
      when 'debug' then Logger::DEBUG
      when 'info' then Logger::INFO
      when 'warn' then Logger::WARN
      when 'error' then Logger::ERROR
      when 'fatal' then Logger::FATAL
      end
    harvestdor.logger.level = config_level ? config_level : Logger::INFO
    harvestdor.logger
  end

  def solr_client
    harvestdor.solr
  end

  def metrics
    harvestdor.metrics
  end

  # per this Indexer's config options
  #  harvest the druids via DorFetcher
  #   create a Solr document for each druid
  #   write the result to the Solr index
  #  (all members of the collection + coll rec itself)
  def harvest_and_index(nocommit = nil)
    nocommit = config.nocommit if nocommit.nil?

    start_time = Time.now.getlocal
    logger.info("Started harvest_and_index at #{start_time}")

    logger.info("Will index est. #{estimated_num_to_index} resources")

    # Note:  harvestdor.each_resource is smart enough to use Enumeraton
    count = 1
    harvestdor.each_resource(in_threads: 1) do |res|
      index_with_exception_handling(res, estimated_num_to_index, count)
      count += 1
    end

    unless nocommit
      logger.info('Beginning Commit.')
      solr_client.commit!
      logger.info('Finished Commit.')
    else
      logger.info('Skipping commit per nocommit flag')
    end

    @total_time = elapsed_time(start_time)
    logger.info("Finished harvest_and_index at #{Time.now.getlocal}")
    logger.info("Total elapsed time for harvest and index: #{(@total_time / 60).round(2)} minutes")

    log_results
    email_results
  end

  # Computed from the whitelist of druids, where the druids may be for collection or item objects
  def estimated_num_to_index
    @estimated_num_to_index ||= begin
      est_num_to_index = 0
      @harvestdor.druids.each do |druid|
        res = Harvestdor::Indexer::Resource.new(@harvestdor, druid)
        est_num_to_index += res.items.size + 1
      end
      est_num_to_index
    end
  end

  # @param [Harvestdor::Indexer::Resource] resource
  # @param [String] est_coll_size the size of the collection
  # @param [String] ix the index of this document (nth to be indexed)
  def index_with_exception_handling(resource, est_coll_size = '?', ix = '?')
    index(resource, est_coll_size, ix)
  rescue => e
    @error_count += 1
    @druids_failed_to_ix << resource.druid
    logger.error "Failed to index item #{resource.druid}: #{e.message} #{e.backtrace}"
    raise e
  end

  # @param [Harvestdor::Indexer::Resource] resource
  # @param [String] coll_size the size of the collection
  # @param [String] ix the index of this document (nth to be indexed)
  def index(resource, est_coll_size = '?', ix = '?')
    doc_hash = solr_document resource
    # note: a collection resource won't have a solr_document
    if doc_hash
      run_hook :before_index, resource, doc_hash
      solr_client.add(doc_hash, est_coll_size, ix)
    end
  end

  # Create a Solr doc, as a Hash, to be added to the SearchWorks Solr index.
  # Solr doc contents are based on the mods, contentMetadata, etc. for the resource's druid
  # @param [Resoure] resource
  # @param [Stanford::Mods::Record] MODS metadata as a Stanford::Mods::Record object
  # @return [Hash] Hash representing the Solr document, or nil if resource is a collection
  def solr_document(resource)
    unless resource.collection?
      sdb = Profiler::SolrDocBuilder.new(resource.bare_druid, harvestdor_client, logger)
      doc_hash = sdb.doc_hash
      doc_hash[:collection] = config.coll_fld_val ? config.coll_fld_val : config.default_set

      # add things from Indexer level class (info kept here for caching purposes)
      doc_hash
    end
  end

  # count the number of records in solr for this collection (and the collection record itself)
  #  and check for a purl in the collection record
  def num_found_in_solr(fqs)
    params = { fl: 'id', rows: 1000 }
    params[:fq] = fqs.map { |k, v| "#{k}:\"#{v}\"" }
    params[:start] ||= 0
    resp = solr_client.client.get 'select', params: params
    num_found = resp['response']['numFound'].to_i

    num_found += num_found_in_solr id: fqs[:collection] if fqs.key? :collection

    num_found
  end

  # create messages about various record counts
  # @return [Array<String>] Array of messages suitable for notificaiton email and/or logs
  def record_count_msgs
    @record_count_msgs ||= begin
      msgs = []
      msgs << "Successful count (items + coll record indexed w/o error): #{metrics.success_count}"

      harvestdor.resources.select(&:collection?).each do |collection|
        solr_count = num_found_in_solr(collection: collection.bare_druid)
        msgs << "#{config.harvestdor.log_name.chomp('.log')} indexed coll record is: #{collection.druid}\n"
        msgs << "coll title: #{coll_title(collection)}\n"
        msgs << "Solr query for items: #{config[:solr][:url]}/select?fq=collection:#{collection.druid}&fl=id,title_245a_display\n"
        msgs << "Records verified in solr for collection #{collection.druid} (items + coll record): #{num_found_in_solr collection: collection.bare_druid}"
        msgs << "WARNING: Expected #{collection.druid} to contain #{collection.items.size} items, but only found #{solr_count}."
      end

      msgs << "Error count (items + coll record w any error; may have indexed on retry if it was a timeout): #{metrics.error_count}"
      #      msgs << "Retry count: #{@retries}"  # currently useless due to bug in harvestdor-indexer 0.0.12
      msgs << "Total records processed: #{metrics.total}"
      msgs
    end
  end

  # log details about the results of indexing
  def log_results
    record_count_msgs.each do |msg|
      logger.info msg
    end
    logger.info("Avg solr commit time per object (successful): #{(@total_time_to_solr / metrics.success_count).round(2)} seconds") unless metrics.success_count == 0
    logger.info("Avg solr commit time per object (all): #{(@total_time_to_solr / metrics.total).round(2)} seconds") unless metrics.total == 0
    logger.info("Avg parse time per object (successful): #{(@total_time_to_parse / metrics.success_count).round(2)} seconds") unless metrics.success_count == 0
    logger.info("Avg parse time per object (all): #{(@total_time_to_parse / metrics.total).round(2)} seconds") unless metrics.total == 0
    logger.info("Avg complete index time per object (successful): #{(@total_time / metrics.success_count).round(2)} seconds") unless metrics.success_count == 0
    logger.info("Avg complete index time per object (all): #{(@total_time / metrics.total).round(2)} seconds") unless metrics.total == 0
  end

  def email_report_body
    body = ''
    body += "\n" + record_count_msgs.join("\n") + "\n"

    if @druids_failed_to_ix.size > 0
      body += "\n"
      body += "records that may have failed to index (merged recs as druids, not ckeys): \n"
      body += @druids_failed_to_ix.join("\n") + "\n"
    end

    body += "\n"
    body += "full log is at gdor_indexer/shared/#{config.harvestdor.log_dir}/#{config.harvestdor.log_name} on #{Socket.gethostname}"
    body += "\n"

    body + @validation_messages.to_s + "\n"
  end

  # email the results of indexing if we are on one of the harvestdor boxes
  def email_results
    if config.notification
      to_email = config.notification

      opts = {}
      opts[:subject] = "#{config.harvestdor.log_name.chomp('.log')} into Solr server #{config[:solr][:url]} is finished"
      opts[:body] = email_report_body
      begin
        send_email(to_email, opts)
      rescue => e
        logger.error('Failed to send email notification!')
        logger.error(e)
      end
    end
  end

  def send_email(to, opts = {})
    opts[:server] ||= 'localhost'
    opts[:from] ||= 'gryphondor@stanford.edu'
    opts[:from_alias] ||= 'gryphondor'
    opts[:subject] ||= 'default subject'
    opts[:body] ||= 'default message body'
    mail = Mail.new do
      from opts[:from]
      to to
      subject opts[:subject]
      body opts[:body]
    end
    mail.deliver!
  end

  def elapsed_time(start_time, units = :seconds)
    elapsed_seconds = Time.now.getlocal - start_time
    case units
    when :seconds
      return elapsed_seconds.round(2)
    when :minutes
      return (elapsed_seconds / 60.0).round(1)
    when :hours
      return (elapsed_seconds / 3600.0).round(2)
    else
      return elapsed_seconds
    end
  end

  protected #-------------------------------------------------------------------

  def harvestdor_client
    @harvestdor_client ||= Harvestdor::Client.new(config_yml_path: @yml_path)
  end

  private #---------------------------------------------------------------------

  def insert_field(solr_doc, field, values, *args)
    Array(values).each do |v|
      Solrizer.insert_field solr_doc, field, v, *args
    end
  end

end
