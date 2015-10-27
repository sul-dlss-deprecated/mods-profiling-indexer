require 'logger'

require 'harvestdor'
require 'stanford-mods'
require 'profiler/xml_solr_doc_builder'

module Profiler
  # Class to build the Hash representing a Solr document for a particular druid
  class SolrDocBuilder

    # The druid of the item
    attr_reader :druid
    # Stanford::Mods::Record
    attr_reader :smods_rec
    attr_reader :logger

    # @param [String] druid, e.g. ab123cd4567
    # @param [Harvestdor::Client] harvestdor client used to get MODS
    # @param [Logger] logger for indexing messages
    def initialize(druid, harvestdor_client, logger)
      @druid = druid
      @harvestdor_client = harvestdor_client
      @logger = logger
      @smods_rec = smods_rec
    end

    # Create a Hash representing the Solr doc to be written to Solr, based on MODS
    # @return [Hash] Hash representing the Solr document
    def doc_hash
      doc_hash = {
        id: @druid
      }

      xsdb = XmlSolrDocBuilder.new
      xml_hash = xsdb.doc_hash(@smods_rec.mods_ng_xml)
      unless xml_hash.empty?
        doc_hash[:all_text_ti] = xml_hash[:mods_sim].first if xml_hash[:mods_sim]

        xml_hash.keys.each do |k|
          if k != :mods_sim
            # remove mods_ prefix from field names
            doc_hash[k.to_s.sub(/^mods_/, '').to_sym] = xml_hash[k]
          end
        end
      end

      doc_hash
    end

    # TODO: move this method to indexer;  initialize should have druid and mods_ng_xml as args
    # return the MODS for the druid as a Stanford::Mods::Record object
    # @return [Stanford::Mods::Record] created from the MODS xml for the druid
    def smods_rec
      if @mods_rec.nil?
        ng_doc = @harvestdor_client.mods @druid
        fail "Empty MODS metadata for #{druid}: #{ng_doc.to_xml}" if !ng_doc.root || ng_doc.root.xpath('//text()').empty?
        @mods_rec = Stanford::Mods::Record.new
        @mods_rec.from_nk_node(ng_doc.root)
      end
      @mods_rec
    end

  end # SolrDocBuilder class
end