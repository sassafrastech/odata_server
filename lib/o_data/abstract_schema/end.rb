require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class End
      extend Forwardable
      include Mixins::Schematize

      def_delegators :association, :schema

      cattr_reader :end_option_names
      @@end_option_names = %w{nullable multiple polymorphic}

      @@end_option_names.each do |option_name|
        define_method(:"#{option_name.to_s}?") do
          !!self.options[option_name.to_sym]
        end
      end

      attr_reader :entity_type, :association
      attr_accessor :options, :name

      def initialize(association, entity_type, name, options = {})
        @association = association
        @name = name
        @entity_type = entity_type

        @options = {}
        options.keys.select { |key| @@end_option_names.include?(key.to_s) }.each do |key|
          @options[key.to_sym] = options[key]
        end
      end

      def return_type
        if options[:multiple]
          'Collection(' + qualified_name + ')'
        else
          qualified_name
        end
      end

      def qualified_name
        schema.qualify(name.camelize)
      end

      def to_multiplicity
        m = (@options[:nullable] ? '0' : '1') + '..' + (@options[:multiple] ? '*' : '1')
        m = '1' if m == '1..1'
        m = '*' if m == '0..*'
        m = '*' if m == '1..*'
        m
      end

      def inspect
        "#<< #{qualified_name}(return_type: #{return_type}, to_multiplicity: #{to_multiplicity}) >>"
      end
    end
  end
end
