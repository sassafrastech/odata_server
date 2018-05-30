module Odata
  module Core
    module Options
      class SelectOption < Odata::Core::Option
        def self.option_name
          '$select'
        end

        attr_reader :properties

        def initialize(query, properties = [])
          @properties = properties
          
          super(query, self.class.option_name)
        end
        
        def self.applies_to?(query)
          return false if query.segments.empty?
          (query.segments.last.is_a?(Odata::Core::Segments::CollectionSegment) || query.segments.last.is_a?(Odata::Core::Segments::NavigationPropertySegment))
        end

        def self.parse!(query, key, value = nil)
          return nil unless key == self.option_name
          
          if query.segments.last.respond_to?(:navigation_property)
            navigation_property = query.segments.last.navigation_property
            
            raise Odata::Core::Errors::InvalidOptionValue.new(query, self.option_name) if navigation_property.to_end.polymorphic?
          end
          
          if query.segments.last.respond_to?(:entity_type)
            entity_type = query.segments.last.entity_type
            
            properties = value.to_s.strip == "*" ? entity_type.properties : value.to_s.split(/\s*,\s*/).collect { |path|
              if md = path.match(/^([A-Za-z_]+)$/)
                property_name = md[1]
                
                property = entity_type.properties.find { |p| p.name == property_name }
                raise Odata::Core::Errors::PropertyNotFound.new(query, property_name) if property.blank? and entity_type.navigation_properties.find{ |np| np.name == property_name}.blank?

                property
              else
                raise Odata::Core::Errors::PropertyNotFound.new(query, path)
              end
            }.compact

            query.Option(self, properties)
          else
            raise Odata::Core::Errors::InvalidOptionContext.new(query, self.option_name) unless value.blank?
          end
        end
        
        def entity_type
          return nil if self.query.segments.empty?
          return nil unless self.query.segments.last.respond_to?(:entity_type)
          @entity_type ||= self.query.segments.last.entity_type
        end

        def valid?
          entity_type = self.entity_type
          return false if entity_type.blank?
          
          @properties.is_a?(Array) && @properties.all? { |property|
            property.is_a?(Odata::AbstractSchema::Property) && !!entity_type.properties.find { |p| p == property }
          }
        end
        
        def value
          "'" + @properties.collect(&:name).join(',') + "'"
        end
      end
    end
  end
end
