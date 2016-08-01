module OData
  module ActiveRecordSchema
    class NavigationProperty < OData::AbstractSchema::NavigationProperty
      def self.name_for(reflection)
        reflection.name.to_s
      end

      def initialize(schema, entity_type, reflection)
        @entity_type = entity_type
        super(schema, entity_type, self.class.name_for(reflection), Association(reflection), source: true)
      end

      def method_name
        self.association.reflection.name.to_sym
      end

      def find_all(one, key_values = {})
        results = one.send(method_name)
        unless key_values.blank?
          if results.respond_to?(:where)
            results = results.where(self.entity_type.conditions_for_find(key_values)).to_a
          else
            # TODO: raise exception if key_values supplied for non-finder method
          end
        end
        results = results.to_a if results.class <= ActiveRecord::Relation
        results
      end

      def find_one(one, key_value = nil)
        results = one.send(method_name)
        unless key_value.blank?
          if results.respond_to?(:find)
            results = results.find(key_value)
          else
            # TODO: raise exception if key_value supplied for non-finder method
          end
        end
        results
      end

      def Association(*args)
        self.association = Association.new(self, *args)
      end
    end
  end
end
