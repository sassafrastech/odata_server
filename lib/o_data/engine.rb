module OData
  class Engine < Rails::Engine
  end

  mattr_accessor :parent_controller
  @@parent_controller = "ApplicationController"

end