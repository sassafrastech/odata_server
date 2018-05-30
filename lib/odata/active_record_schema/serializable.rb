module Odata
	module ActiveRecordSchema
	  module Serializable
      # def self.atom_method_names
      #   Odata::AbstractSchema::Serializable.atom_element_names.collect { |atom_element_name| "odata_atom_#{atom_element_name}_column" }
      # end
	  end
	end
end

Odata::AbstractSchema::Serializable.atom_element_names.each do |atom_element_name|
  odata_active_record_method_name = :"odata_atom_#{atom_element_name}"
  odata_entity_type_method_name = :"atom_#{atom_element_name}_for"
  
  Odata::ActiveRecordSchema::EntityType.instance_eval do
    define_method(odata_entity_type_method_name) do |one|
      if one.class.respond_to?(odata_active_record_method_name)
        result = one.class.send(odata_active_record_method_name)
        
        if result.is_a?(Symbol)
          one.send(result)
        elsif result.is_a?(Proc)
          result.call(one)
        else
          result
        end
      elsif one.respond_to?(odata_active_record_method_name)
        one.send(odata_active_record_method_name)
      elsif one.respond_to?(atom_element_name)
        one.send(atom_element_name)
      else
        super(one)
      end
    end
  end
end
