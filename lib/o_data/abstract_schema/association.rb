require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class Association
      extend Forwardable
      include Mixins::Schematize

      def_delegators :@navigation_property, :schema, :entity_type

      cattr_reader :polymorphic_namespace_name
      @@polymorphic_namespace_name = '$polymorphic'

      cattr_reader :end_option_names
      @@end_option_names = %w{nullable multiple polymorphic}

      @@end_option_names.each do |option_name|
        define_method(:"#{option_name.to_s}?") do
          !!self.options[option_name.to_sym]
        end
      end

      attr_reader :navigation_property
      attr_accessor :options

      def initialize(navigation_property, name, options = {})
        @navigation_property = navigation_property
        @name = name

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

    end
  end
end
