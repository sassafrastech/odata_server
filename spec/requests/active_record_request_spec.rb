require "rails_helper"

describe OData::ActiveRecordSchema::Base do
  context "render" do
    let(:options) { {} }
    let(:schema) { OData::ActiveRecordSchema::Base.new("Test", classes: [ActiveFoo, ActiveBar], **options) }

    before do
      ODataController.data_services.append_schemas([schema])
    end

    after do
      ODataController.data_services.clear_schemas
    end

    def expect_output(expected)
      get(path)
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(expected)
    end

    context "root" do
      let(:path) { "/odata" }

      it "renders as expected" do
        expect_output({
          "@odata.context" => "http://www.example.com/odata/$metadata",
          value: [
            { name: "ActiveFoos", kind: "EntitySet", url: "ActiveFoos" },
            { name: "ActiveBars", kind: "EntitySet", url: "ActiveBars" }
          ]
        }.to_json)
      end

      context "with hook" do
        let(:options) do
          {
            transform_json_for_root: lambda do |json|
              json[:value].push({ name: "Fake data" })
              json
            end
          }
        end

        it "renders as expected" do
          expect_output({
            "@odata.context" => "http://www.example.com/odata/$metadata",
            value: [
              { name: "ActiveFoos", kind: "EntitySet", url: "ActiveFoos" },
              { name: "ActiveBars", kind: "EntitySet", url: "ActiveBars" },
              { name: "Fake data" }
            ]
          }.to_json)
        end
      end
    end
  end
end
