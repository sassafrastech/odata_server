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

        def singular_name
          name.to_s.singularize
        end

        def plural_name
          name.to_s.pluralize
        end

        def inspect
          "#<< #{@schema.namespace}(<< #{@name.inspect}: #{self.class.name.to_s} >>) >>"
        end

      end
    end
  end
end
