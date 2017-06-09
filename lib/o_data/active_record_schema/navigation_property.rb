module OData
  module ActiveRecordSchema
    class NavigationProperty < OData::AbstractSchema::NavigationProperty
      def self.name_for(reflection)
        reflection.name.to_s
      end

      def initialize(parent_entity_type, reflection)
        @parent_entity_type = parent_entity_type
        entity_type = klass(self.class.name_for(reflection))
        super(parent_entity_type, entity_type, self.class.name_for(reflection), Association(reflection))
      end

      def method_name
        self.association.reflection.name.to_sym
      end

      def find_all(one, key_values = {})
        results = one.send(method_name)
        results = self.entity_type.scope.nil? ? results : results.send(self.entity_type.scope)
        results.where(self.entity_type.conditions_for_find(key_values))
      end

      def find_one(one, key_value = nil)
        results = one.send(method_name)
        results = self.entity_type.scope.nil? ? results : results.send(self.entity_type.scope)
        results.find(key_value)
      end

      def Association(*args)
        self.association = Association.new(self, *args)
      end

      def klass(name=@name)
        response = nil
        begin
          response = Object.const_get(name.camelize)
        rescue
          response = Object.const_get(name.sub(/s$/, '').camelize)
        end
        response
      end

      def partner
        reflection_map = Hash[klass.reflections.map{|k,v| [k.classify,v]}] unless klass.nil?
        p = reflection_map[parent_entity_type.name.to_s] unless reflection_map.nil?
        relation_name = self.name.to_s.classify if p
        relation_name = relation_name.pluralize if relation_name.present? && self.association.options[:multiple]
        #relation_name
        p.name.to_s.classify if p
      end
    end
  end
end
