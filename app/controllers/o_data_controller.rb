class ODataController < ApplicationController
  include ActionController::MimeResponds
  include ActionController::Helpers

  cattr_reader :data_services
  @@data_services = OData::Edm::DataServices.new.freeze

  cattr_reader :parser
  @@parser = OData::Core::Parser.new(@@data_services).freeze

  rescue_from OData::ODataException, :with => :handle_exception
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_exception

  skip_before_action :verify_authenticity_token, only: :options

  # This action needs to register first.
  # Clients may override the method if they want to do something.
  before_action :before_action
  def before_action; end

  before_action :parse_url, only: :resource
  before_action :set_request_format!, only: :resource
  after_action :set_header

  %w{service metadata resource}.each do |method_name|
    define_method(:"redirect_to_#{method_name}") do
      # redirect_to(send(:"o_data_#{method_name}_url"))
      redirect_to(params.merge(:action => method_name.to_s))
    end
  end

  def service
    respond_to do |format|
      format.xml  # service.xml.builder
      format.json do
        schema = @@data_services.schemas.first
        json = {
          "@odata.context" => o_data_engine.metadata_url,
          value: @@data_services.to_json
        }
        render json: schema.transformers[:root].call(json)
      end
    end
  end

  def metadata
    respond_to do |format|
      format.xml  # metadata.xml.builder
    end
  end

  def options
    render text: 'Allow: GET', status: :ok
  end

  def resource
    @last_segment = @query.segments.last
    @results = @query.execute!

    case @last_segment.class.segment_name
    when OData::Core::Segments::CountSegment.segment_name
      render text: @results.to_i
    when OData::Core::Segments::ValueSegment.segment_name
      render text: @results.to_s
    when OData::Core::Segments::PropertySegment.segment_name
      path = @query.segments.map(&:value).join('/')

      respond_to do |format|
        format.atom do
          render 'property_segment', locals: {
            key: @results.keys.first.name,
            type: @results.keys.first.return_type,
            value: @results.values.first
          }
        end
        format.json do
          render 'property_segment', locals: {
            path: path,
            value: @results.values.first
          }
        end
      end
    when OData::Core::Segments::NavigationPropertySegment.segment_name
      @countable = @last_segment.countable?
      @results = Array(@results).compact
      navigation_property = @last_segment.navigation_property
      @expand_navigation_property_paths = @query.options[:$expand].try(:navigation_property_paths)

      @entity_type =
          if navigation_property.association.polymorphic?
            if @countable
              @query.segments.first.entity_type
            else
              @query.data_services.find_entity_type(@results.first.class)
            end
          else
            navigation_property.entity_type
          end

      raise OData::Core::Errors::EntityTypeNotFound.new(query, @results.first.class.name) if @entity_type.blank?

      respond_to do |format|
        format.atom # resource.atom.builder
        format.json # resource.json.erb
      end
    when OData::Core::Segments::CollectionSegment.segment_name
      @countable = @last_segment.countable?
      @results = Array(@results).compact
      @entity_type = @last_segment.entity_type
      @expand_navigation_property_paths = @query.options[:$expand].try(:navigation_property_paths)

      respond_to do |format|
        format.atom # resource.atom.builder
        format.json # resource.json.erb
      end
    else
      # in theory, this branch is unreachable because the <tt>parse_resource_path_and_query_string!</tt>
      # method will throw an exception if the <tt>OData::Core::Parser</tt> fails to match any
      # segment of the resource path.
      raise OData::Core::Errors::CoreException.new(@query)
    end
  end

  private

  def parse_url
    @query = @@parser.parse!(params.except(:controller, :action))
  end

  def set_request_format!
    request.format = @query.options[:$format].try(:value).try(:to_sym) || :json
  end

  def handle_exception(ex)
    request.format = :json

    respond_to do |format|
      format.json do
        render json: { error: { code: '', message: ex.message } }
      end
    end
  end

  def set_header
    response.headers['OData-Version'] = '4.0'
  end

end
