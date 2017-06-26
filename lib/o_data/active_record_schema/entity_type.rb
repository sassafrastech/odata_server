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

      attr_reader :active_record, :scope, :entity_set

      def initialize(schema, active_record, options = {})
        super(schema, self.class.name_for(active_record))

        options.reverse_merge!(:reflect_on_associations => true)

        @active_record = active_record

        @constructor = options[:constructor] || Proc.new{|hash| @active_record.new(hash)}
        @destructor = options[:destructor] || Proc.new{|one| one.destroy if one.respond_to?(:destroy)}

        @scope = options[:scope]

        @entity_set = options[:entity_set]

        @composite_key = options[:composite_key]

        key_property_names = []
        key_properties = []
        if @composite_key.present?
          key_property_names = @composite_key.map{|k| k.to_s}
        else
          key_property_names << self.class.primary_key_for(@active_record).to_s
        end

        # included_fields is a hash keys are fields, values are options
        # if a field is a method, use that accessor, and options to configure everything else, if options blank look for prop and default from there
        unless options[:included_fields].blank?
          @active_record.instance_methods.each do |method_name|
            if options[:included_fields].include?(method_name)
              method_options = options[:included_fields][method_name].merge(get_property_options_from_column(method_name))
              property = self.Property(method_name, method_options)
            end
          end
        end
        @active_record.columns.each do |column_adapter|
          if @properties[column_adapter.name.to_s].blank?
            column_name = column_adapter.name.to_s.underscore.to_sym
            column_options = options[:included_fields].blank? ? {} : options[:included_fields][column_name]
            column_options = (column_options||{}).merge(get_property_options_from_column(column_name))
            property = self.Property(column_adapter, column_options) if options[:included_fields].blank? || options[:included_fields].include?(column_adapter.name.to_s.underscore.to_sym)
          end

          if !property.nil?
            if key_property_names.include?(property.name.underscore)
              key_properties << property
            end
          end
        end

        self.key_property = @composite_key.present? ? key_properties : key_properties.first

        raise OData::Core::Errors::KeyNotIncluded.new(key_property_names.join(', ')) if self.key_property.blank? || (@composite_key.present? && @composite_key.count != self.key_property.count)

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

      def get_property_options_from_column(column_name)
        @active_record.columns.each do |column_adapter|
          if column_adapter.name.to_s.underscore.to_sym == column_name.to_sym
            return {
              return_type: column_adapter.type,
              nullable: column_adapter.null
            }
          end
        end
        {}
      end

      def Property(column, options = {})
        property = Property.new(self, column, options)
        @properties[property.name] = property
        property
      end

      def NavigationProperty(*args)
        navigation_property = NavigationProperty.new(self, *args)
        @navigation_properties[navigation_property.name] = navigation_property
        navigation_property
      end

      def find_all(key_values = {}, options = nil)
        scope = @scope.nil? ? @active_record : @active_record.send(@scope)
        conditions = conditions_for_find(key_values)
        conditions.any? ? scope.where(conditions) : scope
      end

      def find_one(key_value)
        scope = @scope.nil? ? @active_record : @active_record.send(@scope)

        return nil if key_property.blank?
        return nil if key_value.blank?
        return nil if key_property.is_a?(Array) != key_value.is_a?(Array)
        return nil if key_property.is_a?(Array) && key_property.count != key_value.count

        conditions = {}
        if key_property.is_a?(Array)
          conditions = Hash[key_property.map_with_index{|k, i| [k.column_adapter.name.to_sym, key_value[i]]}]
        else
          conditions = {key_property.column_adapter.name.to_sym => key_value}
        end

        scope.where(conditions).first
      end

      def delete_one(one)
        @destructor.call(one)
      end

      def create_one(incoming_data)
        incoming_entity_data = Hash[incoming_data.map{
            |k,v|
          self.properties[k].present? ? [Property.name_for(self.properties[k].column_adapter).to_sym,v] : nil
        }.reject{
            |k,v|
          v.nil?
        }]
        new_entity = @constructor.call(incoming_entity_data)
        expanded_properties = []

        #TODO prevent retrieving/posting associations via config, maybe included fields or something
        self.navigation_properties.each do |assocation_name, odata_association_metadata|
          child_entity_type = odata_association_metadata.entity_type
          if incoming_data.include?(assocation_name) && child_entity_type.present?
            expanded_properties << assocation_name
            if odata_association_metadata.association.multiple?
              incoming_data[assocation_name].each do |incoming_child_data|
                #TODO make expanded_properties recursive
                new_child_entity = child_entity_type.create_one(incoming_child_data)
                proxy = new_entity.send("#{odata_association_metadata.association.reflection.name}")
                proxy << new_child_entity
              end
            else
              new_child_entity = child_entity_type.create_one(incoming_data[assocation_name])
              raise "not sure how to handle this"
              #proxy = new_entity.send("#{odata_association_metadata.association.reflection.name}", new_child_entity)
            end
          end
        end

        [new_entity, expanded_properties]
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

      def sort(results, orderby)
        orderby.each do |pair|
          results = results.order(pair.first.column_adapter.name => pair.last)
        end
        results
      end

    end
  end
end
