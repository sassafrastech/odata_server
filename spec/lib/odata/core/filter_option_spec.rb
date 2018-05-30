require "rails_helper"

describe Odata::Core::Options::FilterOption do
  it "handles integer literals" do
    tokens = Odata::Core::Options::FilterOption.tokenize_filter_query("Prop eq 55")
    expect(tokens.length).to eq(3)
    expect(tokens[2]).to eq("55")
    # handle negative number
    tokens = Odata::Core::Options::FilterOption.tokenize_filter_query("Prop eq -55")
    expect(tokens.length).to eq(3)
    expect(tokens[2]).to eq("-55")
  end
end