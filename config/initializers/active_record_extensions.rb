ActiveSupport.on_load(:active_record) do
	module ActiveRecord
		class Base
			def self.odata(&block)
				OData::ActiveRecordSchema::Base.model(self, &block)
			end
		end
	end
end