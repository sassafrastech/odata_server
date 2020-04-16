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
      # Don't worry about trailing newlines.
      expect(response.body.rstrip).to eq(expected.rstrip)
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

    context "resource" do
      let(:path) { "#{root}/ActiveFoos" }

      before do
        (1..2).each do |n|
          create(:active_foo, name: "test #{n}")
        end
      end

      it "renders as expected" do
        expect_output({
          "@odata.context": "http://www.example.com/odata/$metadata#ActiveFoos",
          value: [
            { Id: 1, Name: "test 1", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" },
            { Id: 2, Name: "test 2", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" }
          ]
        }.to_json)
      end

      context "with feed hook" do
        let(:options) do
          {
            transform_json_for_resource_feed: lambda do |json|
              json[:value].push({ name: "Fake data" })
              json
            end
          }
        end

        it "renders as expected" do
          expect_output({
            "@odata.context": "http://www.example.com/odata/$metadata#ActiveFoos",
            value: [
              { Id: 1, Name: "test 1", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" },
              { Id: 2, Name: "test 2", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" },
              { name: "Fake data" }
            ]
          }.to_json)
        end
      end

      context "with entry hook" do
        let(:options) do
          {
            transform_json_for_resource_entry: lambda do |json|
              json["Name"] = "foo"
              json
            end
          }
        end

        it "renders as expected" do
          expect_output({
            "@odata.context": "http://www.example.com/odata/$metadata#ActiveFoos",
            value: [
              { Id: 1, Name: "foo", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" },
              { Id: 2, Name: "foo", CreatedAt: "2020-01-01T12:00:00Z", UpdatedAt: "2020-01-01T12:00:00Z" },
            ]
          }.to_json)
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
