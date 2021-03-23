# frozen_string_literal: true

module SalsaLabs
  ##
  # Used to request information from Salsa Labs. Handles cookie-based
  # authentication, and raises an exception when the API returns an error.
  ##
  class ApiClient
    attr_reader :authentication_cookie

    def initialize(credentials = {})
      @email = credentials[:email] || ENV['SALSA_LABS_API_EMAIL']
      @password = credentials[:password] || ENV['SALSA_LABS_API_PASSWORD']
      @api_url = credentials[:url] || ENV['SALSA_LABS_API_URL']
      @api_url ||= 'https://hq-salsa.wiredforchange.com'

      @authenticated = false
    end

    def authenticate
      return true if authenticated?

      response = authenticate!

      @authentication_cookie = response.env[:response_headers]['set-cookie']
      @authenticated = Nokogiri::XML(response.body).css('error').empty?
    end

    def authenticated?
      @authenticated
    end

    def fetch(endpoint, params)
      authenticate unless authenticated?

      perform_get_request(endpoint, params).body
    end

    def post(endpoint, params)
      authenticate unless authenticated?

      perform_post_request(endpoint, params).body
    end

    private

    attr_reader :authenticated,
                :email,
                :password

    def authenticate!
      perform_get_request(
        '/api/authenticate.sjs',
        authentication_parameters
      )
    end

    def authentication_parameters
      { email: email, password: password }
    end

    def connection
      @connection ||= Faraday
                      .new(url: @api_url) do |faraday|
        faraday.use Faraday::Request::UrlEncoded
        if ENV['DEBUG']
          faraday.use Faraday::Response::Logger
          faraday.response :logger if ENV['DEBUG']
        end

        Faraday::Utils.default_params_encoder = Faraday::FlatParamsEncoder # do not nest repeated parameters
        faraday.adapter Faraday.default_adapter
      end
    end

    def perform_get_request(endpoint, params)
      response = connection.get do |request|
        request.headers['cookie'] = authentication_cookie.to_s
        request.url("#{endpoint}?#{Faraday::FlatParamsEncoder.encode(params)}", {})
      end

      raise_if_error!(response)

      response
    end

    def perform_post_request(endpoint, params)
      # Tell Salsa we want the response back as XML
      params.update({ 'xml' => true })

      # We need the parameters to stay in the same order as the hash keys, so we're using Net::HTTP
      # directly to construct this request, instead of using Faraday, because Faraday always alphabetizes
      # the parameters.
      uri = URI("#{@api_url}/#{endpoint}?#{Faraday::FlatParamsEncoder.encode(params.to_a)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri, nil, 'cookie' => authentication_cookie.to_s)

      raise_if_error!(response)

      response
    end

    def raise_if_error!(response)
      # Raise SalsaLabs::Error if response.body contains error (need to do this
      # because API always gives 200 but then gives an error in the XML).
      errors = Nokogiri::XML(response.body).css('error')

      if errors.any?
        raise SalsaLabs::Error.new(response),
              "There is an error: #{errors.first.text}"
      end
    end
  end

  ##
  # Object used to translate an attributes hash to API's expected parameter list
  # Deals with weird capitalization
  ##
  class ApiObjectParameterList
    SUPPORTER_STANDARD_FIELDS = %w[supporter_key organization_key chapter_key last_modified date_created title
                                   first_name mi last_name suffix email password receive_email email_status
                                   email_preference soft_bounce_count hard_bounce_count last_bounce
                                   receive_phone_blasts phone cell_phone phone_provider work_phone pager home_fax
                                   work_fax street street_2 street_3 city state zip private_zip_plus_4 county district
                                   country latitude longitude organization department occupation
                                   instant_messenger_service instant_messenger_name web_page alternative_email
                                   other_data_1 other_data_2 other_data_3 notes source source_details
                                   source_tracking_code tracking_code status uid timezone language_code].freeze

    def initialize(attributes)
      @attributes = attributes
      capitalize!
    end

    def capitalize
      capitalized_attributes = {}

      @attributes.each do |key, value|
        # re-capitalize according to Salsa's unique requirements

        # deal with exceptions first
        if %w[key object tag].include? key
          # no change, these must not be capitalized
          capitalized_key = key
        elsif key.end_with? '_key'
          # asdf_key -> asdf_KEY
          parts = key.split('_')
          capitalized_key = [parts[0..-2], parts.last.upcase].join('_')
        elsif key == 'mi'
          # middle initial is special case
          capitalized_key = 'MI'
        elsif key == 'uid'
          # uid is always lower case
          capitalized_key = 'uid'
        elsif key.start_with? 'private'
          # private_ab_cd_1 -> PRIVATE_Ab_Cd_1
          parts = key.split('_')
          last_parts = parts[1..].map(&:capitalize)
          capitalized_key = [parts.first.upcase, last_parts].join('_')
        elsif !SUPPORTER_STANDARD_FIELDS.include?(key)
          # custom fields are always snake_case
          capitalized_key = key
        else
          # all others are capitalized normally
          capitalized_key = (key.split('_').map(&:capitalize)).join('_')
        end

        capitalized_attributes[capitalized_key] = value
      end

      capitalized_attributes
    end

    def capitalize!
      @attributes = capitalize
    end

    attr_reader :attributes
  end
end
