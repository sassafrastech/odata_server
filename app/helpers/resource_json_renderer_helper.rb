module ResourceJsonRendererHelper

  def o_data_json_feed(query, results, entity_type, options = {})
    entity_type ||= query.segments.first.entity_type

    json = {
      "@odata.context" => "#{o_data_engine.metadata_url}##{entity_type.plural_name}"
    }

    if count_option = query.options[:count] && count_option.value == 'true'
      json['@odata.count'] = results.size
    end

    json[:value] = results.collect { |result| o_data_json_entry(query, result, entity_type, options) }
    json
  end

  def o_data_json_entry(query, result, entity_type, options = {})
    entity_type ||= query.data_services.find_entity_type(result.class)
    raise OData::Core::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?

    resource_uri = o_data_engine.resource_url(entity_type.href_for(result))

    _json = {}
    _json["@odata.context"] = "#{o_data_engine.metadata_url}##{entity_type.plural_name}/$entity" if options[:context]

    get_selected_properties_for(query, entity_type).each do |property|
      _json[property.name.to_s] = property.value_for(result)
    end

    entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
      if navigation_property.partner
        navigation_property_uri = "#{resource_uri}/#{navigation_property.partner}"

        _json[navigation_property.name.to_s] = begin
          if options[:expand] && options[:expand].keys.include?(navigation_property)
            expand = options[:expand][navigation_property]
            if navigation_property.association.multiple?
              o_data_json_feed(query, navigation_property.find_all(result), navigation_property.entity_type, options.merge(expand: expand))
            else
              o_data_json_entry(query, navigation_property.find_one(result), navigation_property.entity_type, options.merge(expand: expand))
            end
          else
            { "#{navigation_property.partner}@odata.navigationLink" => navigation_property_uri }
          end
        end
      end
    end

    _json
  end

end
