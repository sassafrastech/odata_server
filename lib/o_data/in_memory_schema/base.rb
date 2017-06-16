module OData
  module InMemorySchema
    class Base < OData::AbstractSchema::Base
      attr_reader :classes

      def initialize(namespace = "OData", options = {})
        super(namespace)
        @classes = Array(options[:classes])
        self.register(classes, options[:key])
      end

      def register(cls, key = nil)
        if (cls.respond_to?(:each))
          cls.each do |c|
            register(c, key)
          end
        else
          if (find_entity_type(cls))
            raise OData::Core::Errors::EntityTypeAlreadyRegistered.new(cls.name)
          end
          self.EntityType(cls, key: key)
        end
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        @entity_types[entity_type.name] = entity_type
        entity_type
      end

      def find_entity_type(name)
        name.respond_to?(:name) ? super(name.name.demodulize) : super
      end
    end
  end
end
