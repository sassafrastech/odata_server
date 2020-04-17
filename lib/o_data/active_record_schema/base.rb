module OData
  module ActiveRecordSchema
    class Base < OData::AbstractSchema::Base
      attr_reader :classes, :reflection, :transformers

      def initialize(namespace = 'OData', options = {})
        super(namespace)
        @classes = Array(options[:classes])
        @reflection = options[:reflection] || false
        # Data transformer hooks.
        # See spec/requests/ for examples of how these can be used.
        @transformers = options[:transformers] || {}
        noop = ->(x) { x }
        @transformers[:metadata] ||= noop
        @transformers[:root] ||= noop
        @transformers[:feed] ||= noop
        @transformers[:entry] ||= noop

        if classes.any?
          path = classes.map { |klass| Rails.root.to_s + "/app/models/#{klass}.rb" }
          models = classes
        else
          path = Rails.root.to_s + '/app/models/*.rb'
          models = ActiveRecord::Base.descendants.reject do |active_record|
            active_record == ActiveRecord::SchemaMigration || active_record.abstract_class
          end
        end

        unless options[:skip_require]
          Dir.glob(path).each { |file| require file }
        end

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
    end
  end
end
