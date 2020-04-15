require "rails_helper"

describe OData::ActiveRecordSchema::Base do
  context "render" do
    let(:root) { "/odata" }
    let(:schema) { OData::ActiveRecordSchema::Base.new("Test", classes: [ActiveFoo, ActiveBar]) }

    before do
      ODataController.data_services.append_schemas([schema])
    end

    it "root" do
      expected = {
        "@odata.context" => "http://www.example.com/odata/$metadata",
        value: [
          { name: "ActiveFoos", kind: "EntitySet", url: "ActiveFoos" },
          { name: "ActiveBars", kind: "EntitySet", url: "ActiveBars" }
        ]
      }.to_json

      get(root)
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(expected)
    end
  end
end
