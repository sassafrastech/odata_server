module OData
  module ActiveRecordSchema
    class NavigationProperty < OData::AbstractSchema::NavigationProperty
      def self.name_for(reflection)
        reflection.name.to_s
      end

      def initialize(entity_type, reflection)
        @entity_type = entity_type
        super(entity_type, self.class.name_for(reflection), Association(reflection))
      end

      def method_name
        self.association.reflection.name.to_sym
      end

      def find_all(one, key_values = {})
        results = one.send(method_name)
        results.where(self.entity_type.conditions_for_find(key_values))
      end

      def find_one(one, key_value = nil)
        results = one.send(method_name)
        results.find(key_value)
      end

      def Association(*args)
        # TODO: Will this handle repeat groups for us?
        self.association = Association.new(self, *args)
      end

      def partner
        # TODO: This doesn't work for named relations, e.g. `belongs_to :reviewer, class_name: "User"`
        p = Object.const_get(name.camelize).reflections[entity_type.name.to_sym]
        p.name.camelize if p
      end
    end
  end
end
