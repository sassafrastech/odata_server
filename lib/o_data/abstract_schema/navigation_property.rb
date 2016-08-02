require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class NavigationProperty
      include Mixins::Schematize

      attr_reader :entity_type, :schema
      attr_accessor :association, :the_end, :name

      def initialize(schema, entity_type, name, association, options = {})
        @schema = schema
        @name = name
        @entity_type = entity_type
        @association = association
        @the_end = @association.the_end

        name = name.pluralize if @the_end.options[:multiple]
      end

      def camelized_name
        name.camelize
      end

      def return_type
        the_end.return_type
      end

      def find_all(one, key_values = {})
        nil
      end

      def find_one(one, key_value = nil)
        nil
      end

      def Association(*args)
        self.association = Association.new(self, *args)
      end

      def partner
        nil
      end
    end
  end
end
