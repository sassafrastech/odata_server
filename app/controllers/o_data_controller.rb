class ODataController < OData.parent_controller.constantize
  include ActionController::MimeResponds
  include ActionController::Helpers

  cattr_reader :data_services
  @@data_services = OData::Edm::DataServices.new.freeze

  cattr_reader :parser
  @@parser = OData::Core::Parser.new(@@data_services).freeze

  rescue_from OData::ODataException, :with => :handle_exception
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_exception

  #TODO! remove resource and use https://issues.oasis-open.org/browse/ODATA-262
  skip_before_action :verify_authenticity_token, only: [:options, :resource]

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

      if request.request_method == 'POST'
        #create an @entity_type.active_record object
        #reverse map from body, basically opposite of ResourceJsonRendererHelper (or xml)
        return handle_exception("only JSON POST supported", 501) if request.format != 'application/json'
        begin
          incoming_data = params.except(:format, :controller, :action, :path)

          new_entity, expanded_properties = @entity_type.create_one(incoming_data)

          return handle_exception("cannot create #{@entity_type.name}", 501) if new_entity.nil?

          if new_entity.save
            #TODO other security concerns or validations, like at least one child required, can only set certain values, or default values
            response.status = 201
            @countable = false
            @results = [new_entity]
            @expand_navigation_property_paths = Hash[expanded_properties.map{|p| [@entity_type.navigation_properties[p], {}]}]
          else
            response.status = 400
            return render json: convert_ar_errors_to_metadata_errors(new_entity.errors.messages)
          end
        rescue ActiveRecord::RecordInvalid => invalid
          return handle_exception(convert_ar_errors_to_metadata_errors(invalid.record.errors.messages), 400)
        rescue ActiveRecord::RecordNotUnique => invalid
          return handle_exception(convert_ar_errors_to_metadata_errors(invalid.record.errors.messages), 409)
        end
      elsif request.request_method == 'DELETE'
        return handle_exception("cannot delete multiple #{@entity_type.name}", 400) if @countable
        return head 404 if !@countable && @results.empty?
        obj = @results.first
        if obj.present?
          @entity_type.delete_one(obj)
        end
      elsif request.request_method == 'GET'
        return head 404 if !@countable && @results.empty?
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

  def convert_ar_errors_to_metadata_errors(errors_hash)
    Hash[errors_hash.map{
        |k,v|
      [@entity_type.find_property_by_column_name(k).name, v]
    }]
  end

  def parse_url
    @query = @@parser.parse!(params.except(:controller, :action), request.query_parameters)
  end

  def set_request_format!
    request.format = @query.options[:$format].try(:value).try(:to_sym) || :json
  end

  def handle_exception(ex, status_code=500)
    request.format = :json
    response.status = status_code

    respond_to do |format|
      format.json do
        render json: { error: { code: '', message: ex.respond_to?(:message) ? ex.message : ex } }
      end
    end
  end

  def set_header
    response.headers['OData-Version'] = '4.0'
  end

end
