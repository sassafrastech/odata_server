# OData Server

:warning: If you are not Sassafras, you're probably using the wrong branch.
Try [`rails_5`](https://github.com/sassafrastech/odata_server/tree/rails_5) instead.

The below README may not reflect the current state.

---

This is a rails plugin/engine to embue your application with OData features (so its data can be readily
consumed by an OData client).

In OData, a service exposes a number of workspace. Each workspace is backed by a schema and contains
a collection of entity collections. An entity collection is a related set of records.

Configure the plugin by adding a number of schema objects to `OData::Edm::DataServices.schemas`. Each
schema is an instance of a subclass of `OData::AbstractSchema::Base`. We currently only support two
implementations, and the specific implementation determines how to load the records, mapping the
records' properties to/from Edm data types, and handling filtering, sorting, and data retrieval.

- OData::ActiveRecordSchema::Base -- either you give it a list or it iterate over all your models exposing each as OData entities

and

- OData::InMemorySchema::Base -- this takes in a list of objects which are exposed as OData entities

The accessible OData service will be a read-only provider.

This code is not heavily tested.  It is alpha quality at best. Expect the API to change drastically over time.

## Resources

### Other repos

In case new commits can be pulled in, these are the repos this fork is primarily based on:
- [Live network graph](https://github.com/synbioz/odata_server/network)
- https://github.com/synbioz/odata_server/commits/master
- https://github.com/timbogit/odata_server/commits/rails_5_2
- https://github.com/owenscorning/odata_server/commits/master

### OData V4

* http://www.odata.org
* http://www.odata.org/documentation

## Dependencies

Rails 4 or higher.

## Installation

Put this line in your Gemfile:

```
gem 'odata_server'
```

Run the bundle command to install it.

Then add the following lines to an initializer (ex: `odata_server.rb`):

```
# ActiveRecordSchema

ar_schema = OData::ActiveRecordSchema::Base.new('AR', classes: Foo)
OData::Edm::DataServices.schemas << ar_schema

# OR

OData::Edm::DataServices.schemas << OData::ActiveRecordSchema::Base.new
```

By giving a list of classes to ActiveRecordSchema, it will represent only theses classes. Without `classes` option, all the models will be represented.
ActiveRecordSchema can take a `reflection` option too (default is false): if true the models associations will be shown.

```
# InMemorySchema

class Foo
  attr_reader :foo, :bar, :baz

  def initialize(foo, bar, baz)
    @foo = foo
    @bar = bar
    @baz = baz
  end

  def sel.all
    (1..20).map do |n|
      Foo.new(n, "test", "test #{n}")
    end
  end
end

inmem = OData::InMemorySchema::Base.new("InMem", classes: Foo)
OData::Edm::DataServices.schemas << inmem
```

ActiveRecordSchema and InMemorySchema can either take a single classe or an array of classes.

Then, mount the `OData::Engine` in `routes.rb`:

```
mount OData::Engine, at: '/service/OData'
```

Restart your sever and you can visit the `/service/Odata` url that is the service base.

See https://github.com/lmcalpin/odata_provider_example_rb for an example application that
uses this gem.

## Other options

In addition to `:classes` and `:reflection`, you can use:

- `:transformers`: Hash allowing the following data transformer hooks (ActiveRecord only for now):
    - `:root`: Transform the JSON before output for `/`
    - `:metadata`: Transform the schema before output to XML for `/$metadata`
    - `:feed`: Transform the JSON before output for a resource feed, e.g. `/Categories`
    - `:entry`: Transform the JSON before output for a resource entry, e.g. `/Categories(1)`
- `:skip_require`: `true` if you want to skip automatically requiring each ActiveRecord class (for example if your app loads them itself)
- `:skip_add_entity_types`: `true` if you want to skip automatically adding an EntityType for each ActiveRecord class (you must add them manually, which allows you to customize things like `:name` and `:where`)

## TODOS

* Update and add more tests
* Review XML rendering
* Update the core for OData v4
* Add support for `$search` option

## Development

To develop odata_server itself:

### Setup

1. Install dependencies: `bundle`

### Testing

1. `rspec`
