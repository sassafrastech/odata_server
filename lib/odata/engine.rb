module Odata
  class Engine < ::Rails::Engine
    isolate_namespace Odata
    engine_name 'odata_engine'

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
  end
end
