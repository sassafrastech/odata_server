module ResourceJsonRenderer
  extend ActiveSupport::Concern

  included do
    helper_method :o_data_json_feed, :o_data_json_entry
  end

  def o_data_json_feed(query, results, options = {})
    entity_type = options[:entity_type] || query.segments.first.entity_type

    results_json = {
      "@odata.context" => "#{o_data_engine.metadata_url}##{entity_type.plural_name}",
      value: results.collect { |result| o_data_json_entry(query, result, options.merge(deferred: false)) }
    }

    if inlinecount_option = query.options.find { |o| o.option_name == OData::Core::Options::InlinecountOption.option_name }
      if inlinecount_option.value == 'allpages'
        _json = {
          "results" => results_json,
          "__count" => results.length.to_s
        }

        return _json
      end
    end

    results_json
  end

  def o_data_json_entry(query, result, options = {})
    entity_type = options[:entity_type] || query.data_services.find_entity_type(result.class)
    raise OData::Core::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?

    resource_uri = o_data_engine.resource_url(entity_type.href_for(result))

    if options[:deferred]
      {
        "__deferred" => {
          "uri" => resource_uri
        }
      }
    else
      _json = {}
      _json["@odata.context"] = "#{o_data_engine.metadata_url}##{entity_type.plural_name}/$entity" if options[:context]

      get_selected_properties_for(query, entity_type).each do |property|
        unless %w{__deferred __metadata}.include?(property.name.to_s)
          _json[property.name.to_s] = property.value_for(result)
        else
          # TODO: raise JSONException (property with reserved name)
        end
      end

      entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
        unless %w{__deferred __metadata}.include?(navigation_property.name.to_s)
          navigation_property_uri = resource_uri + '/' + navigation_property.name.to_s

          _json[navigation_property.name.to_s] = begin
            if (options[:expand] || {}).keys.include?(navigation_property)
              if navigation_property.association.multiple?
                o_data_json_feed(query, navigation_property.find_all(result), options.merge(:entity_type => navigation_property.entity_type, :expand => options[:expand][navigation_property], :d => false))
              else
                o_data_json_entry(query, navigation_property.find_one(result), options.merge(:entity_type => navigation_property.entity_type, :expand => options[:expand][navigation_property], :d => false))
              end
            else
              {
                "__deferred" => {
                  "uri" => navigation_property_uri
                }
              }
            end
          end
        else
          # TODO: raise JSONException (navigation property with reserved name)
        end
      end

      _json
    end
  end

end
