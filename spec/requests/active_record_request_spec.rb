require "rails_helper"

describe OData::ActiveRecordSchema::Base do
  context "render" do
    let(:root) { "/odata" }
    let(:options) { {} }
    let(:schema) { OData::ActiveRecordSchema::Base.new("Test", classes: [ActiveFoo, ActiveBar], **options) }

    before do
      Timecop.freeze("2020-01-01T12:00Z")
      ODataController.data_services.append_schemas([schema])
    end

    after do
      ODataController.data_services.clear_schemas
      Timecop.return
    end

    def expect_output(expected)
      get(path)
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(expected)
    end

    context "root" do
      let(:path) { root }

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

    context "$metadata" do
      let(:path) { "#{root}/$metadata" }

      it "renders as expected" do
        expect_output(file_fixture("metadata_basic.xml").read)
      end

      context "with hook" do
        let(:options) do
          {
            transform_schema_for_metadata: lambda do |schema|
              schema.namespace = "Test2"
              schema.entity_types["ActiveFoo"].properties["Name"] = SimpleProperty.new("Name")
              schema
            end
          }
        end

        it "renders as expected" do
          expect_output(file_fixture("metadata_after_hook.xml").read)
        end
      end
    end
  end
end

# This can be used instead of Property, e.g. for rendering $metadata.
class SimpleProperty
  attr_reader :name, :return_type

  def initialize(name)
    @name = name
    @return_type = :TestType
  end

  def nullable?
    true
  end
end
