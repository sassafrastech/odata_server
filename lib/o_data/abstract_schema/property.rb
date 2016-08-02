require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class Property
      extend Forwardable
      include Mixins::Schematize

      def_delegators :@entity_type, :schema

      cattr_reader :edm_null
      @@edm_null = 'Edm.Null'.freeze

      attr_reader :entity_type, :schema
      attr_accessor :return_type, :nullable

      def initialize(entity_type, name, return_type = @@edm_null, nullable = true)
        @entity_type = entity_type
        @name = name
        @return_type = return_type
        @nullable = nullable
      end

      def nullable?
        !!@nullable
      end

      def value_for(one)
        one.send(@name)
      end

      def qualified_name
        @entity_type.qualified_name.to_s + '#' + self.name
      end

      def inspect
        "#<< {qualified_name.to_s}(return_type: #{@return_type.to_s}, nullable: #{nullable?}) >>"
      end
    end
  end
end
