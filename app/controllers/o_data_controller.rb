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
        json = {
          "@odata.context" => o_data_engine.metadata_url,
          value: @@data_services.to_json
        }
        render json: json
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
      render :text => @results.to_i
    when OData::Core::Segments::LinksSegment.segment_name
      request.format = :atom unless request.format == :json

      respond_to do |format|
        format.atom  { render :inline => "xml.instruct!; @results.empty? ? xml.links('xmlns' => 'http://www.w3.org/2005/Atom') : xml.links('xmlns' => 'http://www.w3.org/2005/Atom') { @results.each { |r| xml.uri(o_data_engine.resource_url(r[1])) } }", :type => :builder }
        format.json { render :json => { "links" => @results.collect { |r| { "uri" => r } } }.to_json }
      end
    when OData::Core::Segments::ValueSegment.segment_name
      render :text => @results.to_s
    when OData::Core::Segments::PropertySegment.segment_name
      request.format = :atom unless request.format == :json
      path = @query.segments.map(&:value).join('/')

      respond_to do |format|
        format.atom  { render :inline => "xml.instruct!; value.blank? ? xml.tag!(key.to_sym, 'm:null' => true, 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:m' => 'http://docs.oasis-open.org/odata/ns/metadata') : xml.tag!(key.to_sym, value, 'edm:Type' => type, 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:edm' => 'http://docs.oasis-open.org/odata/ns/edm')", :locals => { :key => @results.keys.first.name, :type => @results.keys.first.return_type, :value => @results.values.first }, :type => :builder }
        format.json do
          json = {
            "@odata.context" => "#{o_data_engine.metadata_url}##{path}",
            value: @results.values.first
          }
          render json: json
        end
      end
    when OData::Core::Segments::NavigationPropertySegment.segment_name
      @countable = @last_segment.countable?
      @results = Array(@results).compact

      @navigation_property = @last_segment.navigation_property
      @polymorphic = @navigation_property.association.polymorphic?

      if @polymorphic
        @entity_type = nil
        @entity_type_name = @navigation_property.name.singularize
      else
        @entity_type = @navigation_property.entity_type
        @entity_type_name = @entity_type.name
      end

      @collection_name = @entity_type_name.pluralize

      @expand_navigation_property_paths = {}
      if expand_option = @query.options[:expand]
        @expand_navigation_property_paths = expand_option.navigation_property_paths
      end

      respond_to do |format|
        format.atom # resource.atom.builder
        format.json # resource.json.erb
      end
    when OData::Core::Segments::CollectionSegment.segment_name
      @countable = @last_segment.countable?
      @results = Array(@results).compact

      @navigation_property = nil
      @polymorphic = true

      @entity_type = @last_segment.entity_type

      @expand_navigation_property_paths = {}
      if expand_option = @query.options[:expand]
        @expand_navigation_property_paths = expand_option.navigation_property_paths
      end

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
    format_option = @query.options[:format]
    if format_option && format_option.value
      request.format = format_option.value.to_sym
    end
  end

  def handle_exception(ex)
    request.format = :json

    respond_to do |format|
      format.json do
        render json: { error: { code: "", message: ex.message } }
      end
    end
  end

  def set_header
    response.headers['OData-Version'] = '4.0'
  end

end
