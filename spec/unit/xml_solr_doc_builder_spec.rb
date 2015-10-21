require 'spec_helper'

RSpec.describe Profiler::XmlSolrDocBuilder do

  before(:all) do
    @xsdb = Profiler::XmlSolrDocBuilder.new
  end

  context "doc_hash" do
    before(:all) do
      ng_doc = Nokogiri::XML('<e a="a1">
                                <e1>v1</e1>
                                <e2>v2</e2>
                                <e2>v3</e2>
                              </e>')
      @hash = @xsdb.doc_hash(ng_doc)
    end
    it "should have an entry for each top level element" do
      expect(@hash).to include(:e_e1_sim)
      expect(@hash).to include(:e_e2_sim)
    end
    it "should have an entry value for each occurrence of a repeated element" do
      expect(@hash).to include(:e_e2_sim => ['v2', 'v3'])
    end
    it "should have an entry for the root element " do
      expect(@hash).to include(:e_sim)
    end
    it "should have entries for attributes on the root element" do
      expect(@hash).to include(:e_a_sim => ['a1'])
    end
  end

  context "doc_hash_from_element" do
    it "creates an entry for the element name symbol, value all the text descendants of the element" do
      ng_el = Nokogiri::XML('<e>v</e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to include(:e_sim => ['v'])
    end
    it "does not create an entry for an empty element with no attributes" do
      ng_el = Nokogiri::XML('<e></e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to be_empty
      ng_el = Nokogiri::XML('<e/>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to be_empty
    end
    it "does not create an entry for an element with only whitespace and no attributes" do
      ng_el = Nokogiri::XML('<e>     </e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to be_empty
    end
    it "has an entry for each attribute on an element" do
      ng_el = Nokogiri::XML('<e at1="a1" at2="a2">v1</e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to include(:e_at1_sim => ['a1'])
      expect(@xsdb.doc_hash_from_element(ng_el)).to include(:e_at2_sim => ['a2'])
    end
    it "includes namespace prefix in the Hash key symbol" do
      ng_el = Nokogiri::XML('<e xml:lang="zurg">v1</e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).to include(:e_xml_lang_sim => ['zurg'])
    end
    it "does not create an entry for an empty attribute" do
      ng_el = Nokogiri::XML('<e at1="">v1</e>').root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).not_to include(:e_at1_sim)
    end
    it "does not create an entry for an attribute containing only whitespace" do
      ng_doc = Nokogiri::XML('<e at1="   ">v1</e>')
      ng_el = ng_doc.root.xpath('/e').first
      expect(@xsdb.doc_hash_from_element(ng_el)).not_to include(:e_at1_sim)
    end
    context "element children" do
      before(:all) do
        ng_doc = Nokogiri::XML('<e>
                                  <e1>v1</e1>
                                  <e2>v2</e2>
                                  <e2>v3</e2>
                                </e>')
        @ng_el = ng_doc.root.xpath('/e').first
        @hash = @xsdb.doc_hash_from_element(@ng_el)
      end
      it "includes the values of the element children in its value, separated by space" do
        expect(@hash).to include(:e_sim => ['v1 v2 v3'])
      end
      it "creates an entry for each subelement" do
        expect(@hash).to include(:e_e1_sim => ['v1'])
        expect(@hash).to include(:e_e2_sim => ['v2', 'v3'])
      end
      it "has all attribute values across multiple children" do
        ng_doc = Nokogiri::XML('<e>
                                  <e1>v1</e1>
                                  <e2 at2="a2">v2</e2>
                                  <e2 at2="a3">v3</e2>
                                </e>')
        ng_el = ng_doc.root.xpath('/e').first
        expect(@xsdb.doc_hash_from_element(ng_el)).to include(:e_e2_at2_sim => ['a2', 'a3'])
      end
    end
  end # doc_hash_from_element

end