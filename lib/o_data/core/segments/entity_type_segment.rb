module OData
  module Core
    module Segments
      class EntityTypeSegment < OData::Core::Segment
        include OData::Core::Countable

        attr_reader :entity_type

        def initialize(query, entity_type, value = nil)
          @entity_type = entity_type

          super(query, value || (@entity_type.is_a?(OData::AbstractSchema::EntityType) ? @entity_type.plural_name : @entity_type))
        end

        def self.can_follow?(anOtherSegment)
          false
        end

        def execute!(acc, options = nil)
          return [] if @entity_type.blank?

          @entity_type.find_all
        end

        def valid?(results)
          if countable?
            results.is_a?(Array) || results.is_a?(ActiveRecord::Relation)
          else
            !results.nil?
          end
        end
      end # EntityTypeSegment
    end # Segments
  end # Core
end # OData
