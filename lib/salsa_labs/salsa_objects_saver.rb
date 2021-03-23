# frozen_string_literal: true

module SalsaLabs
  ##
  # Service object to save an object or a collection of objects to the Salsa Labs API.
  ##
  class SalsaObjectsSaver
    PARAMS_TO_SKIP = ['Date_Created', # Not allowed to be changed
                      'Last_Modified', # Not allowed to be changed
                      'organization_KEY', # Comes from authorization, but not something we ever set
                      'Password', # We're not trying to update anyone's password
                      'salsa_deleted', # Reserved field, should not be modified
                      'salesforce_id' # Reserved field, should not be modified
    ].freeze

    def initialize(credentials = {})
      @client = SalsaLabs::ApiClient.new(credentials)
    end

    def save(data)
      parameters = SalsaLabs::ApiObjectParameterList.new(data)

      # Filter out parameters that should not be included
      filtered_params = parameters.attributes.delete_if do |key, _value|
        # foo_boolvalue keys are duplicates of foo keys
        PARAMS_TO_SKIP.include?(key) || key.end_with?('_boolvalue')
      end

      # Turn boolean values into 0/1
      filtered_params.each do |key, value|
        case value
        when TrueClass
          filtered_params[key] = 1
        when FalseClass
          filtered_params[key] = 0
        end
      end

      # 'object' must go first, followed by 'key' if it exists
      ordered_params = { 'object' => filtered_params.delete('object') }
      key = filtered_params.delete('key')
      ordered_params['key'] = key unless key.nil?
      ordered_params.merge!(filtered_params)

      # Send the API call to Salsa
      response = parse_response(api_call(ordered_params))

      # Process the response
      if response.css('success')
        response.css('success').attribute('key').value.to_i
      else
        raise SalsaLabs::Error.new(response),
              "Unable to save object: #{response}"
      end
    end

    # should this be a separate method?
    # or dispatch within save based on argument type?
    def save_many(collection)
      collection.each do |data|
        save(data)
      end
    end

    private

    attr_reader :client

    def api_call(data)
      client.post('/save', data)
    end

    def parse_response(response)
      Nokogiri::XML(response).css('data')
    end
  end
end
