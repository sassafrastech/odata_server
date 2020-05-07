require_relative 'mixins/serializable'

module OData
  module AbstractSchema
    class Base
      include Mixins::Serializable::SchemaInstanceMethods

      attr_accessor :namespace
      attr_accessor :entity_types
      attr_accessor :entity_type_aliases

      def initialize(namespace = "OData")
        @namespace = namespace
        @entity_types = {}
        @entity_type_aliases = {}
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        @entity_types[entity_type.name] = entity_type
        entity_type
      end

      def associations
        @entity_types.collect(&:navigation_properties).flatten.collect(&:association).uniq
      end

      def find_entity_type(name)
        entity_types[name.to_s]
      end

      def qualify(str)
        namespace.to_s + '.' + str.to_s
      end

      def to_json
        { "EntitySets" => @entity_types.collect(&:plural_name).sort }.to_json
      end

    end
  end
end
