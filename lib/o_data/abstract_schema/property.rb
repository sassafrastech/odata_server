require_relative 'mixins/schematize'

module OData
  module AbstractSchema

    # Property MUST be one of theses types
    # or based on one of theses types :
    # http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/part3-csdl/odata-v4.0-errata03-os-part3-csdl-complete.html#_The_edm:Documentation_Element

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

      def set_value_for(one, value)
        one.send("#{@name}=", value)
      end

      def qualified_name
        @entity_type.qualified_name.to_s + '#' + self.name
      end

    end
  end
end
