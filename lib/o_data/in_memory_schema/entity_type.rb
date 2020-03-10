module OData
  module InMemorySchema
    class EntityType < OData::AbstractSchema::EntityType
      def self.primary_key_for(cls)
        cls.primary_key
      end

      attr_reader :cls, :klass

      def initialize(schema, cls, options = {})
        super(schema, cls.name.demodulize)

        key_property_name = options[:key]
        cls_properties = cls.instance_methods - Object.instance_methods
        cls_properties.map { |prop| if cls.instance_method(prop).arity == 0 then prop else nil end }.compact.each do |prop|
          p = self.Property(prop.to_s)
          @key_property = p if key_property_name.to_s == prop.to_s
          p
        end
        # if we aren't given a key, use the object id - this is almost always terrible, but we need to use
        # *something* to identify our objects
        if key_property_name.nil? then
          object_id_property = self.Property('object_id')
          @key_property ||= object_id_property
        end
        @navigation_properties = []
        @klass = schema.classes.find { |c| c.to_s.match(name) }
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
        results = klass.respond_to?(:all) ? klass.all : []
        if key_values.any?
          results.select { |r| key_values.all? { |k, v| r.send(k).to_s == v.to_s } }
        else
          results
        end
      end

      def find_one(key_value)
        return nil if @key_property.blank?
        find_all(key_property.name.underscore => key_value).first
      end

      def exists?(key_value)
        !!find_one(key_value)
      end

      def primary_key_for(one)
        return nil if @key_property.blank?
        @key_property.value_for(one)
      end

    end
  end
end
