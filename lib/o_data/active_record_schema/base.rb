module OData
  module ActiveRecordSchema
    class Config
      class CollectionFilterConfig
        attr_reader :input_proc, :output_proc
        def input(proc)
          @input_proc = proc
        end
        def output(proc)
          @output_proc = proc
        end
      end
      attr_reader :reflection, :included_fields, :constructor, :scope, :destructor, :composite_key, :collection_filter
      def reflection(val = true)
        @reflection = val
      end
      def include_fields(*field_names)
        @included_fields = Hash[field_names.map{|v| [v.to_sym, {}]}]
      end
      def configure(field, options = {})
        @included_fields ||= {}
        @included_fields[field.to_sym] = options
      end
      def constructor(proc)
        @constructor = proc
      end
      def destructor(proc)
        @destructor = proc
      end
      def default_scope(symbol)
        @scope = symbol
      end
      def entity_set(val = true)
        @entity_set = val
      end
      def composite_key(*fields)
        @composite_key = fields
      end
      def collection_filter(&block)
        @collection_filter = CollectionFilterConfig.new
        @collection_filter.instance_eval(&block) if block
      end
    end
    class Base < OData::AbstractSchema::Base
      #attr_reader :classes, :reflection

      def initialize(namespace = 'OData', options = {})
        super(namespace)
        # @classes = Array(options[:classes])
        # @reflection = options[:reflection] || false
				#
        # if classes.any?
        #   path = classes.map { |klass| Rails.root.to_s + "/app/models/#{klass}.rb" }
        #   models = classes
        # else
        #   path = Rails.root.to_s + '/app/models/*.rb'
        #   models = ActiveRecord::Base.descendants.reject do |active_record|
        #     active_record == ActiveRecord::SchemaMigration || active_record.abstract_class
        #   end
        # end
				#
        # Dir.glob(path).each { |file| require file }
				#
        # models.map do |active_record|
        #   self.EntityType(active_record, reflect_on_associations: reflection)
        # end
      end

      def self.model(entity, &block)
        key = begin
          if entity.is_a?(Class)
            entity.name.to_sym
          elsif entity.is_a?(String) || entity.is_a?(Symbol)
            entity.to_sym
          else
            entity.class.name.to_sym
          end
        end

        config = Config.new
        config.instance_eval(&block) if block

        active_record = key.to_s.classify.constantize

        if active_record.table_exists?
          schema_config = OData::Edm::DataServices.get_schema(:ar, OData::ActiveRecordSchema::Base)
          config_hash = config.instance_values.deep_symbolize_keys
          schema_config.EntityType(active_record, config_hash.reject{|k,v| k == :reflection}.merge({reflect_on_associations: config_hash[:reflection]}))
        else
          # TODO warn or something.  this check intended to prevent errors in rake db:migrate for a new odata model, but should fail else
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
