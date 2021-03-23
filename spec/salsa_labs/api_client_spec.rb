# frozen_string_literal: true

require 'spec_helper'
require 'vcr'

describe SalsaLabs::ApiClient do
  let(:api_client) do
    SalsaLabs::ApiClient.new
  end

  describe '#authenticate' do
    it 'stores the cookie from Salsa Labs' do
      VCR.use_cassette 'successful_authentication',
                       match_requests_on: [:path] do
        api_client.authenticate

        cookie = CGI::Cookie.parse(api_client.authentication_cookie)
        expect(cookie).to have_key('JSESSIONID')
        expect(cookie['Path']).to eq(['/'])
      end
    end

    context 'with proper credentials' do
      it 'sets authenticated to be true' do
        VCR.use_cassette 'successful_authentication',
                         match_requests_on: [:path] do
          api_client.authenticate

          expect(api_client.authenticated?).to be_truthy
        end
      end
    end

    context 'with improper credentials' do
      let(:api_client) do
        SalsaLabs::ApiClient.new({ email: 'user@example.com', password: 'incorrect_password' })
      end

      it 'raises an exception' do
        VCR.use_cassette 'unsuccessful_authentication',
                         match_requests_on: [:path] do
          expect do
            api_client.authenticate
          end.to raise_error(SalsaLabs::Error)
        end
      end
    end
  end

  describe '#authenticated?' do
    it 'returns the value of the instance variable @authenticated' do
      api_client.instance_variable_set(:@authenticated, true)

      expect(api_client.authenticated?).to eq(true)
    end
  end

  describe '#post' do
    before :each do
      allow(api_client).to receive(:authenticated?).and_return(true)
    end

    it 'should convert hash parameters to array parameters to Faraday, preserving order' do
      expect_any_instance_of(Net::HTTP).to receive(:post) do |_http, uri, _body, _headers|
        expect(uri.query).to eq 'b=1&a=2&c=3&xml=true'
      end.and_return(double(body: ''))

      api_client.post('/foo', { 'b' => 1, 'a' => 2, 'c' => 3 })
    end
  end

  describe '#fetch' do
    it 'returns actions from the Salsa Labs API' do
      VCR.use_cassette 'successful_authentication', match_requests_on: [:path] do
        api_client.authenticate

        VCR.use_cassette 'get_objects/action', match_requests_on: %i[path query] do
          data = api_client.fetch('/api/getObjects.sjs', { 'object' => 'Action' })
          expect(data.gsub(/\n|\s{2,}/, ''))
            .to eq(salsa_get_objects_for_action_xml_response)
        end

        VCR.use_cassette 'get_objects/action', match_requests_on: %i[path query] do
          data = api_client.fetch('/api/getObjects.sjs', { 'object' => 'Action' })
          expect(data.gsub(/\n|\s{2,}/, ''))
            .to eq(salsa_get_objects_for_action_xml_response)
        end
      end
    end

    it 'returns supporters from the Salsa Labs API' do
      VCR.use_cassette 'successful_authentication', match_requests_on: [:path] do
        api_client.authenticate

        VCR.use_cassette 'get_objects/supporter', match_requests_on: %i[path query] do
          data = api_client.fetch('/api/getObjects.sjs', { 'object' => 'Supporter', 'limit' => 1 })
          expect(data.gsub(/\n|\s{2,}/, ''))
            .to eq(salsa_get_objects_for_supporter_xml_response)
        end
      end
    end

    it 'does an end to end test' do
      VCR.use_cassette 'successful_authentication', match_requests_on: [:path] do
        VCR.use_cassette 'get_objects/supporters_by_email', match_requests_on: %i[path query] do
          supporters = SalsaLabs::SupportersFetcher.new({ 'Email' => 'george@washington.com' },
                                                        { email: 'user@example.com',
                                                          password: 'correct_password' }).fetch
          expect(supporters).to_not be_empty
        end
      end
    end
  end

  def salsa_get_objects_for_action_xml_response
    File.read('spec/fixtures/getObjects.sjs_action.xml').gsub(/\n|\s{2,}/, '')
  end

  def salsa_get_objects_for_supporter_xml_response
    File.read('spec/fixtures/getObjects.sjs_supporter.xml').gsub(/\n|\s{2,}/, '')
  end
end
