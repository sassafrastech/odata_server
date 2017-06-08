module ResourceJsonRendererHelper

  def o_data_json_feed(query, results, entity_type, options = {})
    values = results.collect {
        |result|
      entity_type = query.data_services.find_entity_type(result.class)
      o_data_json_entry(query, result, entity_type, options.merge(navigation_property: (options[:navigation_property]||[])+["#{entity_type.href_for(result)}"]))
    }
    if options[:association].blank? || options[:association] == false
      json = {
        "@odata.context" => "#{o_data_engine.metadata_url}##{(query.segments.map(&:value)+(options[:navigation_property]||[])).join('/')}"
      }

      if count_option = query.options[:$count] && count_option.value == 'true'
        json['@odata.count'] = results.size
      end

      json[:value] = values
    else
      json = values
    end
    json
  end

  def o_data_json_entry(query, result, entity_type, options = {})
    resource_uri = o_data_engine.resource_url(entity_type.href_for(result))

    _json = {}
    _json["@odata.context"] = "#{o_data_engine.metadata_url}##{(query.segments.map(&:value)+(options[:navigation_property]||[])).join('/')}/$entity" if options[:context]

    get_selected_properties_for(query, entity_type).each do |key, property|
      _json[key] = property.value_for(result)
    end

    Hash[entity_type.navigation_properties.sort].values.select(&:partner).each do |navigation_property|
      prop_name = navigation_property.name.to_s
      unless options[:expand] && options[:expand].keys.include?(navigation_property)
        prop_name = "#{navigation_property.name.to_s}@odata.navigationLink"
      end
      _json[prop_name] = begin
        if options[:expand] && options[:expand].keys.include?(navigation_property)
          expand = options[:expand][navigation_property]
          if navigation_property.association.multiple?
            o_data_json_feed(query, navigation_property.find_all(result), navigation_property.entity_type, options.merge(expand: expand, association: true))
          else
            child_result = navigation_property.find_one(result)
            o_data_json_entry(query, child_result, navigation_property.entity_type, options.merge(expand: expand))
          end
        else
          navigation_property_uri = "#{resource_uri}/#{navigation_property.name}"
          navigation_property_uri
        end
      end
    end

    _json
  end

end
