class OpenApiController < ApplicationController
  before_action :set_definition
  before_action :set_navigation

  def show
    if File.file? "_open_api/definitions/#{@definition_name}.json"
      @definition_path = "_open_api/definitions/#{@definition_name}.json"
      @definition_format = 'json'
    elsif File.file? "_open_api/definitions/#{@definition_name}.yml"
      @definition_path = "_open_api/definitions/#{@definition_name}.yml"
      @definition_format = 'yml'
    elsif NexmoApiSpecification::Definition.exists?(@definition_name)
      @definition_path = NexmoApiSpecification::Definition.path(@definition_name)
      @definition_format = 'yml'
    else
      raise 'Definition can not be found'
    end

    if File.file? "_open_api/initialization/#{@definition_name}.md"
      definition_initialization = File.read("_open_api/initialization/#{@definition_name}.md")
      @definition_initialization_content = MarkdownPipeline.new.call(File.read("_open_api/initialization/#{@definition_name}.md"))
      @definition_initialization_config = YAML.safe_load(definition_initialization)
    end

    if File.file? "_open_api/errors/#{@definition_name}.md"
      definition_errors = File.read("_open_api/errors/#{@definition_name}.md")
      @definition_errors_content = MarkdownPipeline.new.call(File.read("_open_api/errors/#{@definition_name}.md"))
    end

    respond_to do |format|
      format.any(:json, :yaml) { send_file(@definition_path) }
      format.html do
        @definition = OasParser::Definition.resolve(@definition_path)
        set_groups
        render layout: 'page-full'
      end
    end
  end

  private

  def set_navigation
    @navigation = :api
  end

  def set_definition
    @definition_name = params[:definition]
  end

  def set_groups
    @groups = @definition.endpoints.group_by { |endpoint| endpoint.raw['x-group'] }

    @groups = @groups.sort_by do |name, _|
      next 999 if name.nil?
      @definition.raw['x-groups'][name]['order'] || 999
    end
  end
end
