module OData
  module ActiveRecordSchema
    class Base < OData::AbstractSchema::Base
      attr_reader :classes, :reflection

      def initialize(namespace = 'OData', options = {})
        super(namespace)
        @classes = Array(options[:classes])
        @reflection = options[:reflection] || false

        # Hooks.
        # See spec/requests/ for examples of how these can be used.
        @transform_json_for_root = options[:transform_json_for_root] || nil
        @transform_schema_for_metadata = options[:transform_schema_for_metadata] || nil
        @transform_json_for_resource_feed = options[:transform_json_for_resource_feed] || nil
        @transform_json_for_resource_entry = options[:transform_json_for_resource_entry] || nil

        if classes.any?
          path = classes.map { |klass| Rails.root.to_s + "/app/models/#{klass}.rb" }
          models = classes
        else
          path = Rails.root.to_s + '/app/models/*.rb'
          models = ActiveRecord::Base.descendants.reject do |active_record|
            active_record == ActiveRecord::SchemaMigration || active_record.abstract_class
          end
        end

        Dir.glob(path).each { |file| require file }

        models.map do |active_record|
          self.EntityType(active_record, reflect_on_associations: reflection)
        end
      end

      def find_entity_type(klass)
        entity_types[EntityType.name_for(klass)]
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        @entity_types[entity_type.name] = entity_type
        entity_type
      end

      def transform_json_for_root(json)
        @transform_json_for_root&.call(json) || json
      end

      def transformed_for_metadata
        @transform_schema_for_metadata&.call(self) || self
      end

      def transform_json_for_resource_feed(json)
        @transform_json_for_resource_feed&.call(json) || json
      end

      def transform_json_for_resource_entry(json)
        @transform_json_for_resource_entry&.call(json) || json
      end
    end
  end
end
