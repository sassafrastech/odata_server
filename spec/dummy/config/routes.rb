Rails.application.routes.draw do
  mount OData::Engine => "/odata"
end
