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
        :id        => 'Edm.Guid',
        :integer   => 'Edm.Int64',
        :string    => 'Edm.String',
        :text      => 'Edm.String',
        :time      => 'Edm.TimeOfDay'
      }.freeze

      attr_reader :column_adapter

      def initialize(entity_type, column_adapter)
        super(entity_type, self.class.name_for(column_adapter), self.class.return_type_for(column_adapter), self.class.nullable?(column_adapter))

        @column_adapter = column_adapter
      end

      def self.return_type_for(column_adapter)
        @@column_adapter_return_types[column_adapter.type]
      end

      def self.name_for(column_adapter)
        column_adapter.name.to_s
      end

      def self.nullable?(column_adapter)
        column_adapter.null
      end

      def value_for(one)
        v = one.send(@column_adapter.name.to_sym)
        return v.to_f if return_type == 'Edm.Decimal' && !v.nil?
        return v.iso8601 if v.respond_to?(:iso8601)
        v
      end
    end
  end
end
