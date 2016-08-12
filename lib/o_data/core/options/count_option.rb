module OData
  module Core
    module Options
      class CountOption < EnumeratedOption
        def self.option_name
          '$count'
        end

        def self.valid_values
          %w{true false}
        end

        def self.applies_to?(query)
          return false if query.segments.empty?
          query.segments.last.is_a?(OData::Core::Segments::CollectionSegment) || query.segments.last.is_a?(OData::Core::Segments::NavigationPropertySegment)
        end
      end
    end
  end
end
