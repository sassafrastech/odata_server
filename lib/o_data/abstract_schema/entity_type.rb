require_relative 'mixins/serializable'
require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class EntityType
      include Mixins::Serializable::EntityTypeInstanceMethods
      include Mixins::Schematize

      attr_reader :key_property, :extra_tags, :schema
      attr_accessor :properties, :navigation_properties

      def self.name_for(object)
        object.class.to_s.gsub('::', '')
      end

      def initialize(schema, name)
        @schema = schema
        @name = name
        @properties = {}
        @key_property = nil
        @navigation_properties = {}
        @extra_tags = {}
      end

      def key_property=(property)
        return nil unless property.is_a?(Property) && find_property(property.name)
        @key_property = property
      end

      def Property(*args)
        property = Property.new(self, *args)
        @properties[property.name] = property
        property
      end

      def NavigationProperty(*args)
        navigation_property = NavigationProperty.new(self, *args)
        @navigation_properties[navigation_property.name] = navigation_property
        navigation_property
      end

      def find_property(name)
        properties[name.to_s]
      end

      def find_navigation_property(name)
        navigation_properties[name.to_s]
      end

      def find_all(key_values = {}, options = nil)
        []
      end

      def find_one(key_value)
        return nil if @key_property.blank?
        find_all(@key_property => key_value).first
      end

      def exists?(key_value)
        !!find_one(key_value)
      end

      def href_for(one)
        @name + '(' + primary_key_for(one).to_s + ')'
      end

      def primary_key_for(one)
        return nil if @key_property.blank?
        @key_property.value_for(one)
      end

      def filter(results, filter)
        results.collect do |entity|
          filter.apply(self, entity)
        end.compact
      end

      def limit(results, limits)
        skip = limits[:$skip].try(:value).try(:to_i) || 0
        top = limits[:$top].try(:value).try(:to_i).try(:-, 1) || -1

        results.slice(skip..top)
      end

    end
  end
end
