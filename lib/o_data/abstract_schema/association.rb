module OData
  module AbstractSchema
    class Association < SchemaObject
      extend Forwardable
      def_delegators :navigation_property, :schema

      cattr_reader :polymorphic_namespace_name
      @@polymorphic_namespace_name = '$polymorphic'

      attr_reader :navigation_property
      attr_accessor :the_end

      def initialize(navigation_property, name, end_options = {})
        @navigation_property = navigation_property
        super(schema, name)

        End(end_options.delete(:entity_type), end_options.delete(:return_type), end_options.delete(:name), end_options)
      end

      def End(*args)
        @the_end = End.new(self, *args)
      end

      def inspect
        "#<< #{qualified_name.to_s}(#{the_end.name.to_s}: #{the_end.return_type.to_s}) >>"
      end
    end
  end
end
