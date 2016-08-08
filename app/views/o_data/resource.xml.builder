xml.instruct!

if @countable
  o_data_atom_feed(xml, @query, @results, expand: @expand_navigation_property_paths)
else
  o_data_atom_entry(xml, @query, @results.first, expand: @expand_navigation_property_paths, context: true)
end
