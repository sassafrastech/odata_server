require "rails_helper"

describe OData::InMemorySchema::Base do

  context "initialize" do

    it "creates a new schema without entities in the OData namespace by default" do
      schema = OData::InMemorySchema::Base.new
      expect(schema.namespace).to eq("OData")
    end

    it "a namespace argument" do
      schema = OData::InMemorySchema::Base.new("TestNamespace")
      expect(schema.namespace).to eq("TestNamespace")
    end

    it "registers entity types passed via the :classes option" do
      schema = OData::InMemorySchema::Base.new("TestNamespace", classes: [Test::Foo, Test::Foo2])
      expect(schema.entity_types.keys).to contain_exactly("Foo", "Foo2")
    end
  end

  context "register" do
    let(:schema) { OData::InMemorySchema::Base.new }
    it "can register and entity type" do
      schema.register(Test::Foo)
      expect(schema.entity_types.size).to eq(1)
    end

    it "removes the module name from the registering entities" do
      schema.register(Test::Foo)
      expect(schema.entity_types.keys).to contain_exactly("Foo")
    end

    it "accepts a key property name" do
      schema.register(Test::Foo, :bar)
      expect(schema.entity_types["Foo"].key_property.name).to eq("Bar")
    end

    it "defaults the key property to ObjectId" do
      schema.register(Test::Foo)
      expect(schema.entity_types["Foo"].key_property.name).to eq("ObjectId")
    end
  end

  context "find_entites" do
    let(:schema) { OData::InMemorySchema::Base.new }

    before { Test::Foo.clear }

    it "accepts classes or class names, ignororing the module part" do
      schema.register(Test::Foo)
      expect(schema.find_entity_type("Foo").name).to eq("Foo")
      expect(schema.find_entity_type(Test::Foo).name).to eq("Foo")
    end

    it "gives access to all entities of a given entity type" do
      schema.register(Test::Foo, :baz)
      foo_entity_type = schema.find_entity_type("Foo")
      (1..20).each do |n|
        Test::Foo.new(n, "test", "test #{n}")
      end
      expect(foo_entity_type.klass.all.size).to eq(20)
      (1..20).each do |n|
        expect(foo_entity_type.find_one("test #{n}")).to_not be_nil
      end
    end
  end
end
