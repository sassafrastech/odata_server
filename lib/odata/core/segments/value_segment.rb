module Odata
  module Core
    module Segments
      class ValueSegment < Odata::Core::Segment
        def self.parse!(query, str)
          return nil unless str.to_s == segment_name

          query.Segment(self)
        end

        def self.segment_name
          "$value"
        end

        def initialize(query)
          super(query, self.class.segment_name)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == PropertySegment
          else
            anOtherSegment.is_a?(PropertySegment)
          end
        end

        def execute!(acc, options = nil)
          # acc
          acc.values.first
        end

        def valid?(results)
          # # results.is_a?(Array)
          # !results.blank?
          true
        end
      end # ValueSegment
    end # Segments
  end # Core
end # Odata
