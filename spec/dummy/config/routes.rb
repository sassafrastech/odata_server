Rails.application.routes.draw do
  mount Odata::Engine => "/odata"
end
