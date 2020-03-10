require "rails_helper"

describe Odata::Core::Parser do

  context "parse!" do
    let(:schema) { Odata::InMemorySchema::Base.new("TestNamespace", classes: Test::Foo) }
    let(:data_services) { Odata::Edm::DataServices.new(Array(schema)) }
    let(:parser) { Odata::Core::Parser.new(data_services) }

    it "parses property filter queries correctly" do
      a = parser.parse! "Foo?$filter=Prop eq 5"
      filter_option = a.options.find { |o| o.option_name == Odata::Core::Options::FilterOption.option_name }
      expect(filter_option.value).to eq("Prop eq 5")
    end

  end

end