xml.instruct!

if value.blank?
  xml.tag!(key.to_sym, 'm:null' => true, 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:m' => 'http://docs.oasis-open.org/odata/ns/metadata')
else
  xml.tag!(key.to_sym, value, 'edm:Type' => type, 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:edm' => 'http://docs.oasis-open.org/odata/ns/edm')
end
