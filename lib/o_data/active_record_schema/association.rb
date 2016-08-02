module OData
  module ActiveRecordSchema
    class Association < OData::AbstractSchema::Association

      attr_reader :reflection

      def initialize(navigation_property, reflection)
        @navigation_property = navigation_property
        super(navigation_property, self.class.name_for(reflection), options_for(reflection))

        @reflection = reflection
      end

      def self.name_for(reflection)
        reflection.name.to_s
      end

      def nullable?(active_record, association_columns)
        association_columns.all? { |column_name|
          column = active_record.columns.find { |c| c.name == column_name }
          column.blank? ? true : column.null
        }
      end

      def active_record_for(reflection)
        reflection.active_record
      end

      # def self.foreign_keys_for(reflection)
      #   [reflection.options[:foreign_key] || reflection.association_foreign_key, reflection.options[:foreign_type]].compact
      # end

      def polymorphic_column_name(reflection, column_name)
        # self.polymorphic_namespace_name.to_s + '.' + (reflection.options[:as] ? reflection.options[:as].to_s.classify : reflection.class_name.to_s) + '#' + column_name.to_s
        self.polymorphic_namespace_name.to_s + '#' + column_name.to_s
      end

      def column_names_for(reflection)
        out = []

        case reflection.macro
        when :belongs_to
          begin
            out << reflection.class_name.constantize.primary_key
          rescue NameError
            out << reflection.options[:anonymous_class].primary_key
          end
          out << reflection.options[:foreign_type] if reflection.options[:polymorphic]
        else
          out << EntityType.primary_key_for(reflection.active_record)
          out << polymorphic_column_name(reflection, 'ReturnType') if reflection.options[:as]
        end

        out
      end

      def options_for(reflection)
        Rails.logger.info("Processing #{reflection.active_record}")

        polymorphic = reflection.options[:polymorphic] == true # || reflection.options[:as]

        multiple = [:has_many, :has_and_belongs_to_many].include?(reflection.macro)

        nullable =
          if reflection.macro == :belongs_to
            nullable?(active_record_for(reflection), column_names_for(reflection))
          else
            true
          end

        name = self.class.name_for(reflection)
        name = name.pluralize if multiple

        { name: name, entity_type: entity_type, multiple: multiple, nullable: nullable, polymorphic: polymorphic }
      end

    end
  end
end
