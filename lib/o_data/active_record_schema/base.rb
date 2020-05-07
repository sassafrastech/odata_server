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

        return if options[:skip_add_entity_types]

        models.each do |active_record|
          add_entity_type(active_record, reflect_on_associations: reflection)
        end
      end

      def find_entity_type(klass)
        name = EntityType.name_for(klass)
        entity_types[name] || entity_type_aliases[name]
      end

      def add_entity_type(active_record, url_name: nil, **options)
        entity_type = EntityType.new(self, active_record, url_name: url_name, **options)
        @entity_types[entity_type.name] = entity_type
        # Alias the entity for fast lookup via URL path.
        @entity_type_aliases[url_name.singularize] = entity_type if url_name
      end
    end
  end
end
