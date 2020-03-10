require "rails_helper"

describe OData::Core::Parser do

  context "parse!" do
    let(:schema) { OData::InMemorySchema::Base.new("TestNamespace", classes: Test::Foo) }
    let(:data_services) { OData::Edm::DataServices.new(Array(schema)) }
    let(:parser) { OData::Core::Parser.new(data_services) }

    it "parses property filter queries correctly" do
      a = parser.parse!(path: "Foo", "$filter" => "Prop eq 5")
      filter_option = a.options.find { |o| o[1].option_name == OData::Core::Options::FilterOption.option_name }
      expect(filter_option[1].value).to eq("Prop eq 5")
    end

  end

end
