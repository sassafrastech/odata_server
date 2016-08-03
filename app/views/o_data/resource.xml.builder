xml.instruct!

if @countable
  o_data_atom_feed(xml, @query, @results, expand: @expand_navigation_property_paths)
else
  first_result = Array(@results).compact.first
  o_data_atom_entry(xml, @query, first_result, expand: @expand_navigation_property_paths, context: true)
end
