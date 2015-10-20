require 'logger'

module Profiler
  # Class to build the Hash representing a Solr document for a particular Nokogiri XML document
  class XmlSolrDocBuilder

    # for each element in this nokogiri document, create key-value pairs:
    #   element_name => text value of all element children
    #   for each attribute of element:
    #      element_name_attribute_name => value of attribute  (??not multivalued! ??)
    #   for each element child of element, the same as above, preceded by parent el
    #      parent_el_name_child_el_name => text value of all child element children ...
    # @param [Nokogiri::XML::Document] ng_doc
    # @param [String] key_suffix a string containing a suffix to put on the hash keys; default is '_sim'
    # @return [Hash<Symbol, Array<String>>] Hash representation of the Solr fields
    def doc_hash(ng_doc, key_suffix = '_sim')
      @key_suffix = key_suffix
      doc_hash_from_element ng_doc.root
    end

    # Create Hash representation of Solr fields for this element and its attribute and element children.
    # @param [Nokogiri::XML::Element] ng_el
    # @param [String] key_prefix a string containing the ancestor element names, e.g. 'name_role_'
    # @return [Hash<Symbol, Array<String>>] Hash representation of the Solr fields for this element
    def doc_hash_from_element ng_el, key_prefix = nil
      el_name = key_prefix ? key_prefix + ng_el.name : ng_el.name
      hash = {}
      # entry for element text content
      el_text = ng_el.text.gsub(/\s+/,' ').strip
      key = "#{el_name}#{@key_suffix}".to_sym
      unless el_text.empty?
        hash[key] ? hash[key] << el_text : hash[key] = [el_text]
      end
      # entry for each element attribute
      ng_el.attribute_nodes.each { |an|
        at_text = an.text.strip
        unless at_text.empty?
          if an.namespace
            key = "#{el_name}_#{an.namespace.prefix}_#{an.name}#{@key_suffix}".to_sym
          else
            key = "#{el_name}_#{an.name}#{@key_suffix}".to_sym
          end
          hash[key] ? hash[key] << at_text : hash[key] = [at_text]
        end
      }
      # recurse for subelements
      ng_el.element_children.each { |en|
        hash.merge!(doc_hash_from_element(en, "#{el_name}_")) { |k, oldval, newval|
          oldval.concat(newval)
        }
      }
      hash
    end

  end # XmlSolrDocBuilder class
end