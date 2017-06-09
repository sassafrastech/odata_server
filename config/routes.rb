OData::Engine.routes.draw do
  get '/' => "o_data#service", as: :service, defaults: { format: 'json' }
  # this is what we want to do, but this doesn't work in Rails 4
  #get '$metadata' => "o_data#metadata", as: :metadata, defaults: { format: 'xml' }
  # this is a workaround
  get ':wtfrails' => "o_data#metadata", as: :metadata,
                                        defaults: { format: 'xml', wtfrails: '$metadata' },
                                        constraints: { wtfrails: /\$metadata/ }
  match '/:wtfrails' => "o_data#options", via: :options,
                                          defaults: { wtfrails: '$metadata' },
                                          constraints: { wtfrails: /\$metadata/ }
  get '*path' => "o_data#resource", as: :resource, defaults: { format: 'json' }
  post '*path' => "o_data#resource", as: :create, defaults: { format: 'json' }

end
