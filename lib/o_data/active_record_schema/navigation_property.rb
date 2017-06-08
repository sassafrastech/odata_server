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
        self.association = Association.new(self, *args)
      end

      def partner
        klass = nil
        begin
          klass = Object.const_get(name.camelize)
        rescue
          klass = Object.const_get(name.sub(/s$/, '').camelize)
        end
        reflection_map = Hash[klass.reflections.map{|k,v| [k.classify,v]}] unless klass.nil?
        p = reflection_map[entity_type.name.to_s] unless reflection_map.nil?
        relation_name = self.name.to_s.classify if p
        relation_name = relation_name.pluralize if relation_name.present? && self.association.options[:multiple]
        #relation_name
        p.name.to_s.classify if p
      end
    end
  end
end
