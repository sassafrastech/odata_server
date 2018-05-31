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
  end

end