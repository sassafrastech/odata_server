xml.instruct!
xml.edmx(:Edmx, Version: "4.0", "xmlns:edmx" => "http://docs.oasis-open.org/odata/ns/edmx") do
  xml.edmx(:DataServices) do

    ODataController.data_services.schemas.each do |schema|
      xml.tag!(:Schema, Namespace: schema.namespace) do

        schema.entity_types.sort_by(&:qualified_name).each do |entity_type|
          next if entity_type.name.include?('HABTM')
          xml.tag!(:EntityType, Name: entity_type.name) do
            unless entity_type.key_property.blank?
              xml.tag!(:Key) do
                xml.tag!(:PropertyRef, Name: entity_type.key_property.name)
              end
            end

            entity_type.properties.each do |property|
              xml.tag!(:Property, Name: property.name, Type: property.return_type, Nullable: property.nullable?)
            end

            entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
              attrs = { Name: navigation_property.name,
                        Type: navigation_property.return_type }
              attrs[:Partner] = navigation_property.partner if navigation_property.partner
              xml.tag!(:NavigationProperty, attrs)
            end
          end
        end

        xml.tag!(:EntityContainer, Name: "#{schema.namespace}Service") do
          schema.entity_types.sort_by(&:qualified_name).each do |entity_type|
            next if entity_type.plural_name.include?('HABTM')
            xml.tag!(:EntitySet, Name: entity_type.plural_name, EntityType: entity_type.qualified_name) do

              entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
                if navigation_property.partner
                  xml.tag!(:NavigationPropertyBinding, Path: navigation_property.partner,
                                                       Target: navigation_property.plural_name)
                end
              end
            end
          end
        end

      end
    end

  end
end
