module OData
  module ActiveRecordSchema
    class Base < OData::AbstractSchema::Base
      attr_reader :classes, :reflection

      def initialize(namespace = 'OData', options = {})
        super(namespace)
        @classes = Array(options[:classes])
        @reflection = options[:reflection] || false

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
          self.EntityType(active_record, reflect_on_associations: false)
        end.map do |entity_type|
          entity_type.active_record.reflect_on_all_associations.each do |reflection|
            entity_type.NavigationProperty(reflection)
          end
        end
      end

      def find_entity_type(klass)
        self.entity_types.find { |et| et.name == EntityType.name_for(klass) }
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        self.entity_types << entity_type
        entity_type
      end
    end
  end
end
