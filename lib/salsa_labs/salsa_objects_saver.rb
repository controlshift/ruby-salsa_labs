module SalsaLabs
  ##
  # Service object to save an object or a collection of objects to the Salsa Labs API.
  ##
  class SalsaObjectsSaver
    PARAMS_TO_SKIP = ['Date_Created',  # Not allowed to be changed
                      'Last_Modified',  # Not allowed to be changed
                      'organization_KEY'  # Comes from authorization, but not something we ever set
    ].freeze

    def initialize(credentials = {})
      @client = SalsaLabs::ApiClient.new(credentials)
    end

    def save(data)
      parameters = SalsaLabs::ApiObjectParameterList.new(data)

      # Filter out parameters that should not be included
      filtered_params = parameters.attributes.delete_if { |key, value| PARAMS_TO_SKIP.include?(key) }

      # 'object' must go first, followed by 'key' if it exists
      ordered_params = {'object' => filtered_params.delete('object')}
      key = filtered_params.delete('key')
      unless key.nil?
        ordered_params['key'] = key
      end
      ordered_params.merge!(filtered_params)
        
      response = parse_response(api_call(ordered_params))

      if response.css('success')
        return response.css('success').attribute('key').value.to_i
      else
        raise SalsaLabs::Error.new(response),
          "Unable to save object: #{response}"
      end
    end

    #should this be a separate method?
    #or dispatch within save based on argument type?
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
