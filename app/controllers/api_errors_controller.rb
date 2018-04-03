class ApiErrorsController < ApplicationController
  before_action :set_definition

  def index
    @errors = load_errors
  end

  def show
    @error = load_errors[params['id']]
  end

  private

  def load_errors
    # Generic errors if we're not reading an OAS
    return YAML.load_file("#{Rails.root}/config/api-errors.yml") unless @definition_name
    # OAS errors if we've provided a definition
    load_errors_from_definition
  end

  def load_errors_from_definition
    errors = {}
    definition = OpenApiDefinitionResolver.find(@definition_name)

    definition.endpoints.each do |endpoint|
      endpoint.responses.each do |r|
        # We only support application/json responses
        resp = r.content['application/json']

        # If this HTTP code has a resolution defined
        if resp['schema'] && resp['schema']['resolution']
          props = resp['schema']['properties']
          resolution = resp['schema']['resolution']

          # Split the link in to path + error title
          link, title = props['type']['example'].split('#')

          # If it's a generic error, we don't want to show it on this page
          next if link.split('/').last == 'generic'

          # All errors must contain error detail and a resolution
          errors[title] = {
              'description' => props['detail']['example'],
              'resolution' => resolution['text']
          }

          # If there's a link, show that too
          errors[title]['link'] = resolution['link'] if resolution['link']
        end
      end
    end

    Hash[errors.sort]
  end

  def set_definition
    @definition_name = params[:definition]
  end
end