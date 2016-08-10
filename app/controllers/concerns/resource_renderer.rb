module ResourceRenderer
  extend ActiveSupport::Concern

  ODataAtomXmlns = {
    "xmlns"   => "http://www.w3.org/2005/Atom",
    "xmlns:m" => "http://docs.oasis-open.org/odata/ns/metadata"
  }.freeze

  def get_selected_properties_for(query, entity_type)
    if select_option = query.options.find { |o| o.option_name == OData::Core::Options::SelectOption.option_name }
      if select_option.entity_type == entity_type
        # entity_type is the $select'ed collection/navigation property
        return select_option.properties
      else
        # entity_type is an $expand'ed navigation property
       if expand_option = query.options.find{ |o| o.option_name == OData::Core::Options::ExpandOption.option_name }
         if expand_option.value.downcase == entity_type.plural_name.downcase
           return entity_type.properties
         end
       else
         return []
       end
      end
    end

    # $select option not supplied
    entity_type.properties
  end

end
