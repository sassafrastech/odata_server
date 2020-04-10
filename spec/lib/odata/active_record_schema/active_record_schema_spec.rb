require "rails_helper"

describe OData::ActiveRecordSchema::Base do
  context "initialize" do
    it "creates a new schema without entities in the OData namespace by default" do
      schema = OData::ActiveRecordSchema::Base.new
      expect(schema.namespace).to eq("OData")
    end

    it "a namespace argument" do
      schema = OData::ActiveRecordSchema::Base.new("TestNamespace")
      expect(schema.namespace).to eq("TestNamespace")
    end

    it "registers entity types passed via the :classes option" do
      schema = OData::ActiveRecordSchema::Base.new("TestNamespace", classes: [ActiveFoo, ActiveBar])
      expect(schema.entity_types.keys).to contain_exactly("ActiveFoo", "ActiveBar")
    end
  end

  context "find_entites" do
    let(:schema) { OData::ActiveRecordSchema::Base.new("TestNamespace", classes: [ActiveFoo, ActiveBar]) }

    it "accepts classes or class names" do
      expect(schema.find_entity_type("ActiveFoo").name).to eq("ActiveFoo")
      expect(schema.find_entity_type(ActiveFoo).name).to eq("ActiveFoo")
    end

    it "gives access to all entities of a given entity type" do
      foo_entity_type = schema.find_entity_type("ActiveFoo")
      (1..20).each do |n|
        create(:active_foo, name: "test #{n}")
      end
      expect(foo_entity_type.active_record.all.size).to eq(20)
      foo_entity_type.active_record.all.each do |foo|
        expect(foo_entity_type.find_one(foo.id)).to_not be_nil
      end
    end
  end
end
