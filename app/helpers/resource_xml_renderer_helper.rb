module ResourceXmlRendererHelper

  ODataAtomXmlns = {
    'xmlns'   => 'http://www.w3.org/2005/Atom',
    'xmlns:m' => 'http://docs.oasis-open.org/odata/ns/metadata',
    'xmlns:d' => 'http://docs.oasis-open.org/odata/ns/data',
    'xmlns:georss' => 'http://www.georss.org/georss',
    'xmlns:gml' => 'http://www.opengis.net/gml'
  }.freeze

  def o_data_atom_feed(xml, query, results, entity_type, options = {})
    results_href, results_url =
      if base_href = options.delete(:href)
        [base_href.to_s, o_data_engine.resource_url(base_href.to_s)]
      else
        [query.resource_path, o_data_engine.resource_url(query.resource_path)]
      end

    results_title = options.delete(:title) || results_href

    xml.tag!(:feed, { 'xml:base' => o_data_engine.service_url,
                      'm:context' => "#{o_data_engine.metadata_url}##{entity_type.plural_name}" }.merge(options[:hide_xmlns] ? {} : ODataAtomXmlns)) do
      xml.tag!(:id, results_url)
      xml.tag!(:title, results_title, type: :text)
      xml.tag!(:updated, Time.now.utc.iso8601)
      xml.tag!(:link, rel: 'self', title: results_title, href: results_href)

      if count_option = query.options[:$count] && count_option.value == 'true'
        xml.m(:count, results.length)
      end

      results.each do |result|
        o_data_atom_entry(xml, query, result, entity_type, options.merge(hide_xmlns: true, href: results_href))
      end
    end
  end

  def o_data_atom_entry(xml, query, result, entity_type, options = {})
    result_href = entity_type.href_for(result)
    result_url = o_data_engine.resource_url(result_href)

    result_title = entity_type.atom_title_for(result)
    result_updated_at = entity_type.atom_updated_at_for(result)

    xml.tag!(:entry, {}.merge(options[:hide_xmlns] ? {} : ODataAtomXmlns)) do
      xml.tag!(:id, result_url) unless result_href.blank?
      xml.tag!(:title, result_title, type: :text) unless result_title.blank?
      xml.tag!(:category, term: "##{entity_type.qualified_name}", scheme: 'http://docs.oasis-open.org/odata/ns/scheme')
      xml.tag!(:updated, result_updated_at.iso8601) unless result_updated_at.blank?

      xml.tag!(:author) do
        xml.tag!(:name)
      end

      unless (properties = get_selected_properties_for(query, entity_type)).empty?
        xml.tag!(:content, type: 'application/xml') do
          xml.m(:properties) do
            properties.each do |key, property|
              property_attrs = { "m:type" => property.return_type }

              unless (value = property.value_for(result)).blank?
                xml.d(key.to_sym, value, property_attrs)
              else
                xml.d(key.to_sym, property_attrs.merge('m:null' => true))
              end
            end
          end
        end
      end

      xml.tag!(:link, rel: 'self', title: result_title, href: result_href) unless result_title.blank? || result_href.blank?

      Hash[entity_type.navigation_properties.sort].values.select(&:partner).each do |navigation_property|
        navigation_property_href = "#{result_href}/#{navigation_property.partner}"
        related_attrs = { rel: "http://docs.oasis-open.org/odata/ns/related/#{navigation_property.partner}",
                          type: "application/atom+xml;type=#{navigation_property.association.multiple? ? 'feed' : 'entry'}",
                          title: navigation_property.partner,
                          href: navigation_property_href }

        if options[:expand] && options[:expand].keys.include?(navigation_property)
          xml.tag!(:link, related_attrs) do
            xml.m(:inline) do
              expand = options[:expand][navigation_property]
              if navigation_property.association.multiple?
                o_data_atom_feed(xml, query, navigation_property.find_all(result), navigation_property.entity_type, options.merge(expand: expand))
              else
                o_data_atom_entry(xml, query, navigation_property.find_one(result), navigation_property.entity_type, options.merge(expand: expand))
              end
            end
          end
        else
          xml.tag!(:link, related_attrs)
        end
      end

    end
  end

end
