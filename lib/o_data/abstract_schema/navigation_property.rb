require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class NavigationProperty
      extend Forwardable
      include Mixins::Schematize

      def_delegators :@entity_type, :schema

      attr_reader :entity_type
      attr_accessor :association

      def initialize(entity_type, name, association, options = {})
        @entity_type = entity_type
        @name = name
        @association = association

        name = name.pluralize if @association.options[:multiple]
      end

      def return_type
        association.return_type
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
