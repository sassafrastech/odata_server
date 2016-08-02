xml.instruct!
xml.tag!(:service, 'xmlns' => 'http://www.w3.org/2007/app',
                   'xmlns:atom' => 'http://www.w3.org/2005/Atom',
                   'xmlns:metadata' => 'http://docs.oasis-open.org/odata/ns/metadata',
                   'xml:base' => o_data_engine.service_url,
                   'metadata:context' => '$metadata') do
  ODataController.data_services.schemas.each do |schema|
    xml.tag!(:workspace) do
      xml.atom(:title, schema.namespace, type: :text)
      schema.entity_types.map(&:plural_name).sort.each do |plural_name|
        next if plural_name.include?('HABTM')
        xml.tag!(:collection, href: plural_name) do
          xml.atom(:title, plural_name, type: :text)
        end
      end
    end
  end
end
