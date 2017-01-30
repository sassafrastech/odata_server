require_relative 'mixins/serializable'
require_relative 'mixins/option_translator'

module OData
  module ActiveRecordSchema
    class EntityType < OData::AbstractSchema::EntityType
      include Mixins::Serializable::EntityTypeInstanceMethods
      include Mixins::OptionTranslator

      def self.name_for(active_record_or_str)
        name = active_record_or_str.is_a?(ActiveRecord::Base) ? active_record_or_str.name : active_record_or_str.to_s
        name.gsub('::', '')
      end

      def self.primary_key_for(active_record)
        active_record.primary_key
      end

      attr_reader :active_record

      def initialize(schema, active_record, options = {})
        super(schema, self.class.name_for(active_record))

        options.reverse_merge!(:reflect_on_associations => true)

        @active_record = active_record

        key_property_name = self.class.primary_key_for(@active_record).to_s

        @active_record.columns.each do |column_adapter|
          property = self.Property(column_adapter)

          if key_property_name == property.name.underscore
            self.key_property = property
          end
        end

        OData::AbstractSchema::Mixins::Serializable.atom_element_names.each do |atom_element_name|
          o_data_entity_type_property_name = :"atom_#{atom_element_name}_property"

          if @active_record.column_names.include?(atom_element_name.to_s)
            property = find_property(atom_element_name)
            next if property.blank?

            self.send(:"#{o_data_entity_type_property_name}=", property)
          end
        end

        if options[:reflect_on_associations]
          @active_record.reflect_on_all_associations.each do |reflection|
            self.NavigationProperty(reflection)
          end
        end
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

      def find_all(key_values = {}, options = nil)
        conditions = conditions_for_find(key_values)
        conditions.any? ? @active_record.where(conditions) : @active_record
      end

      def find_one(key_value)
        return nil if key_property.blank?
        @active_record.find(key_value)
      end

      def conditions_for_find(key_values = {})
        self.class.conditions_for_find(self, key_values)
      end

      def self.conditions_for_find(entity_type, key_values = {})
        return "1=0" unless entity_type.is_a?(OData::ActiveRecordSchema::EntityType)

        Hash[key_values.map do |k, v|
          property = k.is_a?(Property) ? k : entity_type.find_property(k)
          raise OData::Core::Errors::PropertyNotFound.new(nil, k) if property.blank?

          [property.column_adapter.name.to_sym, v]
        end]
      end

      def self.href_for(one)
        one.class.name.pluralize + '(' + one.send(one.class.send(:primary_key)).to_s + ')'
      end

      def href_for(one)
        self.class.href_for(one)
      end

      def filter(results, filter_option)
        filter = filter_option.filter
        translate_filter(results, filter.value, filter.left, filter.right)
      end

      def limit(results, limits)
        limits.each do |key, limit|
          results = translate_limitator(results, key, limit.value)
        end
        results
      end

    end
  end
end
