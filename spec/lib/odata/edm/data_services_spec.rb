require "rails_helper"

describe OData::Edm::DataServices do

  let(:schemas) do
    inmemory1 = OData::InMemorySchema::Base.new
    inmemory1.register(Test::Foo)
    inmemory2 = OData::InMemorySchema::Base.new
    inmemory2.register(Test::Foo2)
    [inmemory1, inmemory2]
  end
  let(:ds) { OData::Edm::DataServices.new(schemas) }

  context "initialize" do
    it "adds all classes in the schemas to the service" do
      expect(ds.entity_types.size).to eq(2)
    end
  end

  context "find_entity" do
    it "only finds registered entity types" do
      expect(ds.schemas.size).to eq(2)
      expect(ds.find_entity_type("Foo").schema).to eq(schemas[0])
      expect(ds.find_entity_type(Test::Foo2).schema).to eq(schemas[1])
      assert(ds.find_entity_type(Test::Empty).nil?)
    end
  end

end
