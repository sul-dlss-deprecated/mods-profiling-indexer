require 'spec_helper'

RSpec.describe Profiler::SolrDocBuilder do

  before(:all) do
    @fake_druid = 'oo000oo0000'
    @ns_decl = "xmlns='#{Mods::MODS_NS}'"
    @mods_xml = "<mods #{@ns_decl}><note>hi</note><name><namePart>Shindy</namePart></name></mods>"
    @ng_mods_xml = Nokogiri::XML(@mods_xml)
  end

  # NOTE:
  # "Doubles, stubs, and message expectations are all cleaned out after each example."
  # per https://www.relishapp.com/rspec/rspec-mocks/docs/scope

  context "doc_hash" do
    before(:each) do
      @hdor_client = double
      allow(@hdor_client).to receive(:mods).with(@fake_druid).and_return(@ng_mods_xml)
      @doc_hash = Profiler::SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash
    end
    it "id field set to druid" do
      expect(@doc_hash[:id]).to eq @fake_druid
    end
    it "all_text_ti field has all the text content of the document" do
      expect(@doc_hash).to include(:all_text_ti => 'hi Shindy')
    end
    it "does not have a field for the mods element" do
      expect(@doc_hash).not_to include(:mods_sim)
    end
    it "does not have mods_ as prefix in field names" do
      @doc_hash.keys.each { |k| expect(k.to_s).not_to match /$mods_.*/}
    end
    it "has a field for each top level element" do
      expect(@doc_hash).to include(:note_sim => ['hi'])
      expect(@doc_hash).to include(:name_sim => ['Shindy'])
      expect(@doc_hash).to include(:name_namePart_sim => ['Shindy'])
    end
    it "calls XmlSolrDocBuilder to populate hash fields from MODS" do
      expect_any_instance_of(Profiler::XmlSolrDocBuilder).to receive(:doc_hash).and_return([])
      Profiler::SolrDocBuilder.new(@fake_druid, @hdor_client, nil).doc_hash
    end
  end

  context "using Harvestdor::Client" do
    before(:all) do
      config_yml_path = File.join(File.dirname(__FILE__), "..", "config", "bnf.yml")
      @indexer = Indexer.new(config_yml_path)
      @real_hdor_client = @indexer.send(:harvestdor_client)
    end
    context "smods_rec method (called in initialize method)" do
      it "returns Stanford::Mods::Record object" do
        expect(@real_hdor_client).to receive(:mods).with(@fake_druid).and_return(@ng_mods_xml)
        sdb = Profiler::SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil)
        expect(sdb.smods_rec).to be_an_instance_of(Stanford::Mods::Record)
      end
      it "raises exception if MODS xml for the druid is empty" do
        expect(@real_hdor_client).to receive(:mods).with(@fake_druid).and_return(Nokogiri::XML("<mods #{@ns_decl}/>"))
        expect { Profiler::SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil) }.to raise_error(RuntimeError, Regexp.new("^Empty MODS metadata for #{@fake_druid}: <"))
      end
      it "raises exception if there is no MODS xml for the druid" do
        expect { Profiler::SolrDocBuilder.new(@fake_druid, @real_hdor_client, nil) }.to raise_error(Harvestdor::Errors::MissingMods)
      end
    end
  end # context using Harvestdor::Client

end