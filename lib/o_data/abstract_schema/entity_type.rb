require_relative 'mixins/serializable'
require_relative 'mixins/schematize'

module OData
  module AbstractSchema
    class EntityType
      include Mixins::Serializable::EntityTypeInstanceMethods
      include Mixins::Schematize

      attr_reader :key_property, :schema
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
      end

      def key_property=(property)
        if property.is_a?(Array)
          return nil if property.select{
              |p|
            !(p.is_a?(Property) && find_property(p.name))}.any?
        else
          return nil unless property.is_a?(Property) && find_property(property.name)
        end
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
        return nil if key_value.blank?
        return nil if @key_property.is_a?(Array) != key_value.is_a?(Array)
        return nil if @key_property.is_a?(Array) && @key_property.count != key_value.count

        conditions = {}
        if @key_property.is_a?(Array)
          conditions = Hash[@key_property.map_with_index{|k, i| [k, key_value[i]]}]
        else
          conditions = {@key_property => key_value}
        end
        find_all(conditions).first
      end

      def delete_one(one)

      end

      def create_one
        nil
      end

      def exists?(key_value)
        !!find_one(key_value)
      end

      def href_for(one)
        @name + '(' + primary_key_for(one).to_s + ')'
      end

      def primary_key_for(one)
        return nil if @key_property.blank?
        if @key_property.is_a?(Array)
          Hash[@key_property.map{|k| [k, k.value_for(one)]}]
        else
          @key_property.value_for(one)
        end
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
