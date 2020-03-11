require_relative 'comparable'

module OData
  module AbstractSchema
    module Mixins
      module Schematize
        include Comparable

        def qualified_name
          schema.qualify(name)
        end

        def <=>(other)
          return qualified_name <=> other.qualified_name if other.is_a?(OData::SchemaObject)
          return -1 if other.blank?
          1
        end

        def name
          @name.to_s.camelize
        end

        def singular_name
          name.singularize
        end

        def plural_name
          # TODO: Pluralize base name, not suffix.
          name.pluralize
        end

      end
    end
  end
end
