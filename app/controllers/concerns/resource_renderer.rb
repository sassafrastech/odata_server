module ResourceRenderer
  extend ActiveSupport::Concern

  def get_selected_properties_for(query, entity_type)
    # $select option not supplied
    return entity_type.properties unless select_option = query.options[:select]

    if select_option.entity_type == entity_type
      # entity_type is the $select'ed collection/navigation property
      select_option.properties
    else
      # entity_type is an $expand'ed navigation property
      if expand_option = query.options[:expand]
        entity_type.properties if expand_option.value.downcase == entity_type.plural_name.downcase
      else
        []
      end
    end
  end

end
