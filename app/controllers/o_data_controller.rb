class ODataController < ApplicationController
  include ActionController::MimeResponds
  include ActionController::Helpers

  @@o_data_atom_xmlns = {
    "xmlns"   => "http://www.w3.org/2005/Atom",
    "xmlns:d" => "http://schemas.microsoft.com/ado/2007/08/dataservices",
    "xmlns:m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata"
  }.freeze

  helper_method :o_data_atom_feed, :o_data_atom_entry, :o_data_json_feed, :o_data_json_entry

  cattr_reader :data_services
  @@data_services = OData::Edm::DataServices.new.freeze

  cattr_reader :parser
  @@parser = OData::Core::Parser.new(@@data_services).freeze

  rescue_from OData::ODataException, :with => :handle_exception
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_exception

  before_action :extract_resource_path_and_query_string, :only => [:resource]
  before_action :parse_resource_path_and_query_string!,  :only => [:resource]
  before_action :set_request_format!,                    :only => [:resource]

  %w{service metadata resource}.each do |method_name|
    define_method(:"redirect_to_#{method_name}") do
      # redirect_to(send(:"o_data_#{method_name}_url"))
      redirect_to(params.merge(:action => method_name.to_s))
    end
  end

  def service
    respond_to do |format|
      # format.xml  # service.xml.builder
      format.xml  { render xml: xml_tags }
      format.json { render :json => @@data_services.to_json }
    end
  end

  def metadata
    respond_to do |format|
      format.xml  # metadata.xml.builder
    end
  end

  def resource
    @last_segment = @query.segments.last

    @results = @query.execute!

    case @last_segment.class.segment_name
    when OData::Core::Segments::CountSegment.segment_name
      render :text => @results.to_i
    when OData::Core::Segments::LinksSegment.segment_name
      request.format = :xml unless request.format == :json

      respond_to do |format|
        format.xml  { render :inline => "xml.instruct!; @results.empty? ? xml.links('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') : xml.links('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') { @results.each { |r| xml.uri(o_data_engine.resource_url(r[1])) } }", :type => :builder }
        format.json { render :json => { "links" => @results.collect { |r| { "uri" => r } } }.to_json }
      end
    when OData::Core::Segments::ValueSegment.segment_name
      render :text => @results.to_s
    when OData::Core::Segments::PropertySegment.segment_name
      request.format = :xml unless request.format == :json

      respond_to do |format|
        format.xml  { render :inline => "xml.instruct!; value.blank? ? xml.tag!(key.to_sym, 'm:null' => true, 'xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices', 'xmlns:m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') : xml.tag!(key.to_sym, value, 'edm:Type' => type, 'xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices', 'xmlns:edm' => 'http://schemas.microsoft.com/ado/2007/05/edm')", :locals => { :key => @results.keys.first.name, :type => @results.keys.first.return_type, :value => @results.values.first }, :type => :builder }
        format.json { render :json => { @results.keys.first.name => @results.values.first }.to_json }
      end
    when OData::Core::Segments::NavigationPropertySegment.segment_name
      @countable = @last_segment.countable?

      @navigation_property = @last_segment.navigation_property
      @polymorphic = @navigation_property.to_end.polymorphic?

      if @polymorphic
        @entity_type = nil
        @entity_type_name = @navigation_property.to_end.name.singularize
      else
        @entity_type = @navigation_property.to_end.entity_type
        @entity_type_name = @entity_type.name
      end

      @collection_name = @entity_type_name.pluralize

      @expand_navigation_property_paths = {}
      if expand_option = @query.options.find { |o| o.option_name == OData::Core::Options::ExpandOption.option_name }
        @expand_navigation_property_paths = expand_option.navigation_property_paths
      end

      respond_to do |format|
        format.xml # resource.xml.builder
        format.json # resource.json.erb
      end
    when OData::Core::Segments::CollectionSegment.segment_name
      @countable = @last_segment.countable?

      @navigation_property = nil
      @polymorphic = true

      @entity_type = @last_segment.entity_type

      @expand_navigation_property_paths = {}
      if expand_option = @query.options.find { |o| o.option_name == OData::Core::Options::ExpandOption.option_name }
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
  def xml_tags
    require 'builder'
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!(:service, 'xmlns:atom': 'http://www.w3.org/2005/Atom' , \
                       'xmlns': 'http://www.w3.org/2007/app', \
                       'xml:base': o_data_engine.service_url, \
                       'xmlns:metadata': 'http://docs.oasis-open.org/odata/ns/metadata', \
                       'metadata:context': '$metadata') do
      @@data_services.schemas.each do |schema|
    	  xml.tag!(:workspace) do
    	    xml.atom(:title, schema.namespace, type: :text)
    	    schema.entity_types.collect(&:plural_name).sort.each do |plural_name|
            next if plural_name.include?('HABTM')
    	      xml.tag!(:collection, :href => plural_name) do
    	        xml.atom(:title, plural_name)
    	      end
    	    end
    	  end
      end
    end
  end

  def extract_resource_path_and_query_string
    @resource_path = params[:path]

    @query_string = params.permit!.to_h.inject({}) { |acc, pair|
      key, value = pair
      acc[key.to_sym] = value unless [@resource_path, :controller, :action].include?(key.to_sym)
      acc
    }.collect { |key, value|
      key.to_s + '=' + value.to_s
    }.join('&')
  end

  def parse_resource_path_and_query_string!
    @query = @@parser.parse!([@resource_path, @query_string].compact.join('?'))
  end

  def set_request_format!
    if format_option = @query.options.find { |o| o.option_name == OData::Core::Options::FormatOption.option_name }
      if format_value = format_option.value
        request.format = format_value.to_sym
      end
    end
  end

  def handle_exception(ex)
    request.format = :xml

    respond_to do |format|
      format.xml { render :inline => "xml.instruct!; xml.error('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata') { xml.code(code.to_s); xml.message(message); xml.uri(uri) }", :type => :builder, :locals => { :code => nil, :message => ex.message, :uri => request.url } }
    end
  end

  def o_data_atom_feed(xml, query, results, options = {})
    results_href, results_url = begin
      if base_href = options.delete(:href)
        [base_href.to_s, o_data_engine.resource_url(base_href.to_s)]
      else
        [query.resource_path, o_data_engine.resource_url(query.to_uri)]
      end
    end

    results_title = options.delete(:title) || results_href

    xml.tag!(:feed, { "xml:base" => o_data_engine.service_url }.merge(options[:hide_xmlns] ? {} : @@o_data_atom_xmlns)) do
      xml.tag!(:title, results_title)
      xml.tag!(:id, results_url)
      xml.tag!(:link, :rel => "self", :title => results_title, :href => results_href)

      unless results.empty?
        if last_result = results.last
          entity_type = options[:entity_type] || query.data_services.find_entity_type(last_result.class)
          if atom_updated_at = entity_type.schema.atom_updated_at_for(last_result)
            xml.tag!(:updated, atom_updated_at.iso8601)
          end unless entity_type.nil?
        end

        results.each do |result|
          o_data_atom_entry(xml, query, result, options.merge(:hide_xmlns => true, :href => results_href))
        end
      end

      if inlinecount_option = query.options.find { |o| o.option_name == OData::Core::Options::InlinecountOption.option_name }
        if inlinecount_option.value == 'allpages'
          xml.m(:count, results.length)
        end
      end
    end
  end

  def o_data_atom_entry(xml, query, result, options = {})
    entity_type = options[:entity_type] || query.data_services.find_entity_type(result.class)
    raise OData::Core::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?

    result_href = entity_type.href_for(result)
    result_url = o_data_engine.resource_url(result_href)

    result_title = entity_type.atom_title_for(result)
    result_summary = entity_type.atom_summary_for(result)
    result_updated_at = entity_type.atom_updated_at_for(result)

    xml.tag!(:entry, {}.merge(options[:hide_xmlns] ? {} : @@o_data_atom_xmlns)) do
      xml.tag!(:id, result_url) unless result_href.blank?
      xml.tag!(:title, result_title, :type => "text") unless result_title.blank?
      xml.tag!(:summary, result_summary, :type => "text") unless result_summary.blank?
      xml.tag!(:updated, result_updated_at.iso8601) unless result_updated_at.blank?

      xml.tag!(:author) do
        xml.tag!(:name)
      end

      xml.tag!(:link, :rel => "edit", :title => result_title, :href => result_href) unless result_title.blank? || result_href.blank?

      unless entity_type.navigation_properties.empty?
        entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
          navigation_property_href = result_href + '/' + navigation_property.name

          navigation_property_attrs = { :rel => "http://schemas.microsoft.com/ado/2007/08/dataservices/related/" + navigation_property.name, :type => "application/atom+xml;type=#{navigation_property.to_end.multiple? ? 'feed' : 'entry'}", :title => navigation_property.name, :href => navigation_property_href }

          if (options[:expand] || {}).keys.include?(navigation_property)
            xml.tag!(:link, navigation_property_attrs) do
              xml.m(:inline, :type => navigation_property_attrs[:type]) do
                if navigation_property.to_end.multiple?
                  o_data_atom_feed(xml, query, navigation_property.find_all(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property]))
                else
                  o_data_atom_entry(xml, query, navigation_property.find_one(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property]))
                end
              end
            end
          else
            xml.tag!(:link, navigation_property_attrs)
          end
        end
      end

      xml.tag!(:category, :term => entity_type.qualified_name, :scheme => "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme")

      unless (properties = get_selected_properties_for(query, entity_type)).empty?
        xml.tag!(:content, :type => "application/xml") do
          xml.m(:properties) do
            properties.each do |property|
              property_attrs = { "m:type" => property.return_type }

              unless (value = property.value_for(result)).blank?
                xml.d(property.name.to_sym, value, property_attrs)
              else
                xml.d(property.name.to_sym, property_attrs.merge("m:null" => true))
              end
            end
          end
        end
      end
    end
  end

  def o_data_json_feed(query, results, options = {})
    results_json = results.collect { |result| o_data_json_entry(query, result, options.merge(:d => false, :deferred => false)) }

    if inlinecount_option = query.options.find { |o| o.option_name == OData::Core::Options::InlinecountOption.option_name }
      if inlinecount_option.value == 'allpages'
        _json = {
          "results" => results_json,
          "__count" => results.length.to_s
        }

        return options[:d] ? { "d" => _json } : _json
      end
    end

    options[:d] ? { "d" => results_json } : results_json
  end

  def o_data_json_entry(query, result, options = {})
    entity_type = options[:entity_type] || query.data_services.find_entity_type(result.class)
    raise OData::Core::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?

    resource_uri = o_data_engine.resource_url(entity_type.href_for(result))
    resource_type = entity_type.qualified_name

    json = begin
      if options[:deferred]
        {
          "__deferred" => {
            "uri" => resource_uri
          }
        }
      else
        _json = {
          "__metadata" => {
            "uri" => resource_uri,
            "type" => resource_type
          }
        }

        get_selected_properties_for(query, entity_type).each do |property|
          unless %w{__deferred __metadata}.include?(property.name.to_s)
            _json[property.name.to_s] = property.value_for(result)
          else
            # TODO: raise JSONException (property with reserved name)
          end
        end

        entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
          unless %w{__deferred __metadata}.include?(navigation_property.name.to_s)
            navigation_property_uri = resource_uri + '/' + navigation_property.name.to_s

            _json[navigation_property.name.to_s] = begin
              if (options[:expand] || {}).keys.include?(navigation_property)
                if navigation_property.to_end.multiple?
                  o_data_json_feed(query, navigation_property.find_all(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property], :d => false))
                else
                  o_data_json_entry(query, navigation_property.find_one(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property], :d => false))
                end
              else
                {
                  "__deferred" => {
                    "uri" => navigation_property_uri
                  }
                }
              end
            end
          else
            # TODO: raise JSONException (navigation property with reserved name)
          end
        end

        _json
      end
    end

    options[:d] ? { "d" => json } : json
  end

  protected

  def get_selected_properties_for(query, entity_type)
    if select_option = query.options.find { |o| o.option_name == OData::Core::Options::SelectOption.option_name }
      if select_option.entity_type == entity_type
        # entity_type is the $select'ed collection/navigation property
        return select_option.properties
      else
        # entity_type is an $expand'ed navigation property
       if expand_option = query.options.find{ |o| o.option_name == OData::Core::Options::ExpandOption.option_name }
         if expand_option.value.downcase == entity_type.plural_name.downcase
           return entity_type.properties
         end
       else
         return []
       end
      end
    end

    # $select option not supplied
    entity_type.properties
  end
end
