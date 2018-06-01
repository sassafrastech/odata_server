require "rails_helper"

describe Odata::InMemorySchema::Base do

  context "initialize" do

    xit "creates a new schema without entities in the Odata namespace by default" do

    end

    xit "a namespace argument" do

    end

    xit "registers entities passed via the :classes option" do

    end
  end

  context "register" do
    let(:schema) { Odata::InMemorySchema::Base.new }
    it "can register and entity type" do
      schema.register(Test::Foo)
      expect(schema.entity_types.size).to eq(1)
    end

    it "removes the module name from the registering entities" do
      schema.register(Test::Foo)
      expect(schema.entity_types[0].name).to eq("Foo")
    end

    it "accepts a key property name" do
      schema.register(Test::Foo, :bar)
      expect(schema.entity_types[0].key_property.name).to eq(:bar.to_s)
    end

    it "defaults the key property to object_id" do
      schema.register(Test::Foo)
      expect(schema.entity_types[0].key_property.name).to eq("object_id")
    end
  end

  context "find_entites" do
    let(:schema) { Odata::InMemorySchema::Base.new }
    it "accepts classes or class names, ignororing the module part" do
      schema.register(Test::Foo)
      expect(schema.find_entity_type("Foo").name).to eq("Foo")
      expect(schema.find_entity_type(Test::Foo).name).to eq("Foo")
    end

    it "gives access to all entities of a given entity type" do
      schema.register(Test::Foo, :baz)
      foo_entity_type = schema.find_entity_type("Foo")
      (1..20).each do |n|
        foo_entity_type.entities.append(Test::Foo.new(n, "test", "test #{n}"))
      end
      expect(foo_entity_type.entities.size).to eq(20)
      (1..20).each do |n|
        expect(foo_entity_type.find_one("test #{n}")).to_not be_nil
      end
    end
  end
end