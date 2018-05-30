Odata::Engine.routes.draw do
  get '/' => "odata#service", :as => :service, :defaults => { :format => 'xml' }
  # this is what we want to do, but this doesn't work in Rails 4
  #get '$metadata' => "odata#metadata", :as => :odata_metadata, :defaults => { :format => 'xml' }
  # this is a workaround
  get ':wtfrails' => "odata#metadata", :as => :metadata, :defaults => { :format => 'xml' },
      :constraints => {wtfrails: /\$metadata/ }
  get '*path' => "odata#resource", :as => :resource, :defaults => { :format => 'json' }
end

