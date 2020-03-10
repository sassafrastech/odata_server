module OData
  module Core
    class Parser
      cattr_reader :reserved_option_names
      @@reserved_option_names = %w{orderby expand select top skip filter format count}.freeze

      def initialize(data_services)
        @data_services = data_services
      end

      def parse!(params, query_params: {})
        query = OData::Core::Query.new(data_services)
        resource_path_components = params[:path].split('/')
        query_string_components = query_params.except(:path)

        resource_path_components.each do |resource_path_component|
          _parse_segment!(query, resource_path_component)
        end

        query_string_components.each do |key, value|
          _parse_option!(query, key, value)
        end

        query
      end

      private

      attr_reader :data_services

      def _parse_segment!(query, resource_path_component)
        Segment.descendants.each do |segment_class|
          if segment_class.can_follow?(query.segments.last)
            if segment = segment_class.parse!(query, resource_path_component)
              return segment
            end
          end
        end

        raise Errors::ParseQuerySegmentException.new(query, resource_path_component)
      end

      def _parse_option!(query, key, value)
        if md = key.match(/^\$(.*?)$/)
          raise Errors::InvalidReservedOptionName.new(query, key, value) unless @@reserved_option_names.include?(md[1])
        end

        if md = value.match(/^'\s*([^']+)\s*'$/)
          value = md[1]
        end

        Option.descendants.each do |option_class|
          if option_class.applies_to?(query)
            if option = option_class.parse!(query, key, value)
              return option
            end
          end
        end

        # basic (or "custom") option
        query.Option(BasicOption, key, value)
      end
    end # Parser
  end # Core
end # OData
