module OData
  module ActiveRecordSchema
    class Base < OData::AbstractSchema::Base
      attr_reader :classes, :reflection

      def initialize(namespace = 'OData', options = {})
        super(namespace)
        @classes = Array(options[:classes])
        @reflection = options[:reflection] || false
        group_by_form = options[:group_by_form] || false

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

        models.each do |active_record|
          if group_by_form
            # TODO: Clean this up and make more efficient.
            forms = Response.distinct.pluck(:form_id).map { |id| ({id: id, name: Form.find(id).name}) }
            forms.each do |id:, name:|
              add_entity_type(active_record, where: {form_id: id}, suffix: name, reflect_on_associations: reflection)
            end
          else
            add_entity_type(active_record, reflect_on_associations: reflection)
          end
        end
      end

      def find_entity_type(klass)
        entity_types[EntityType.name_for(klass)]
      end

      # TODO make a proc?
      def add_entity_type(*args)
        entity_type = EntityType.new(self, *args)
        @entity_types[entity_type.name] = entity_type
      end
    end
  end
end
