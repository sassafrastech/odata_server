module Odata
  module Core
    module Segments
      class EntityTypeSegment < Odata::Core::Segment
        include Odata::Core::Countable

        attr_reader :entity_type

        def initialize(query, entity_type, value = nil)
          @entity_type = entity_type

          super(query, value || (@entity_type.is_a?(Odata::AbstractSchema::EntityType) ? @entity_type.plural_name : @entity_type))
        end

        def self.can_follow?(anOtherSegment)
          false
        end

        def execute!(acc, options = nil)
          return [] if @entity_type.blank?

          @entity_type.find_all
        end

        def valid?(results)
          countable? ? results.is_a?(Array) : !results.blank?
        end
      end # EntityTypeSegment
    end # Segments
  end # Core
end # Odata
