module OData
  module ActiveRecordSchema
    class Property < OData::AbstractSchema::Property
      cattr_reader :column_adapter_return_types
      @@column_adapter_return_types = {
        :binary    => 'Edm.Binary',
        :boolean   => 'Edm.Boolean',
        :byte      => 'Edm.Byte',
        :date      => 'Edm.Date',
        :datetime  => 'Edm.DateTimeOffset',
        :timestamp => 'Edm.DateTimeOffset',
        :float     => 'Edm.Decimal',
        :decimal   => 'Edm.Decimal',
        :integer   => 'Edm.Int32',
        :string    => 'Edm.String',
        :text      => 'Edm.String',
        :time      => 'Edm.TimeOfDay'
      }.freeze

      attr_reader :column_adapter

      def initialize(entity_type, column_adapter, column_options)
        super(entity_type, self.class.name_for(column_adapter), self.class.return_type_for(column_adapter, column_options), self.class.nullable?(column_adapter, column_options))

        @column_adapter = column_adapter
      end

      def self.return_type_for(column_adapter, column_options)
        option_return_type = column_options.try(:[], :return_type)
        raise OData::Core::Errors::MethodNotConfigured.new(column_adapter.to_s) unless option_return_type.present?
        @@column_adapter_return_types[option_return_type]
      end

      def self.name_for(column_adapter)
        column_adapter.is_a?(Symbol) ? column_adapter.to_s : column_adapter.name.to_s
      end

      def self.nullable?(column_adapter, column_options)
        option_nullable = column_options.try(:[], :nullable)
        return option_nullable unless option_nullable.nil?
        column_adapter.null
      end

      def value_for(one)
        column_name = @column_adapter.is_a?(Symbol) ? @column_adapter : @column_adapter.name.to_sym
        v = one.send(column_name)
        return v.to_f if return_type == 'Edm.Decimal'
        return v.iso8601 if v.respond_to?(:iso8601)
        v
      end

      def set_value_for(one, value)
        column_name = @column_adapter.is_a?(Symbol) ? @column_adapter : @column_adapter.name.to_sym
        one.send("#{column_name}=", value)
      end
    end
  end
end
