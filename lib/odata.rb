module Odata
  class OdataException < StandardError
    def to_s
      "An unknown #{self.class.name.demodulize.to_s} has occured."
    end
  end
end

require "odata/abstract_schema"
require "odata/core"

require "odata/active_record_schema"
require "odata/in_memory_schema"
require "odata/edm"
require "odata/engine"
