require 'spec_helper'

describe SalsaLabs::SalsaObjectsSaver do
  let(:credentials) { double }
  let(:api_client) { double }

  subject { SalsaLabs::SalsaObjectsSaver.new(credentials) }

  before :each do
    allow(SalsaLabs::ApiClient).to receive(:new).with(credentials).and_return(api_client)
  end

  describe '#save' do
    let(:attributes) do
      {
        'supporter_key' => '31337',
        'organization_key' => '1234',
        'chapter_key' => '90210',
        'title' => 'Mr.',
        'first_name' => 'John',
        'mi' => 'Jacob',
        'last_name' => 'Jingleheimer Schmidt',
        'suffix' => 'IV',
        'email' => 'johnjacob@example.com',
        'receive_email' => 1,
        'phone' => '1234567890',
        'street' => '123 Main St',
        'street_2' => 'Apt 404',
        'city' => 'Schnechtady',
        'state' => 'NY',
        'zip' => '12345',
        'country' => 'USA',
        'source' => 'rspec',
        'status' => 'Active',
        'source_details' => 'foo123',
        'source_tracking_code' => 'foo123',
        'tracking_code' => 'abc123',
        'date_created' => 'Fri Mar 14 2014 14:07:29 GMT-0400 (EDT)',
        'last_modified' => 'Fri Mar 14 2014 13:54:10 GMT-0400 (EDT)'
      }
    end
    let(:supporter) { SalsaLabs::Supporter.new(attributes) }
    let(:expected_data) do
      {
        'supporter_KEY' => '31337',
        'organization_KEY' => '1234',
        'chapter_KEY' => '90210',
        'Title' => 'Mr.',
        'First_Name' => 'John',
        'MI' => 'Jacob',
        'Last_Name' => 'Jingleheimer Schmidt',
        'Suffix' => 'IV',
        'Email' => 'johnjacob@example.com',
        'Receive_Email' => 1,
        'Phone' => '1234567890',
        'Street' => '123 Main St',
        'Street_2' => 'Apt 404',
        'City' => 'Schnechtady',
        'State' => 'NY',
        'Zip' => '12345',
        'Country' => 'USA',
        'Source' => 'rspec',
        'Status' => 'Active',
        'Source_Details' => 'foo123',
        'Source_Tracking_Code' => 'foo123',
        'Tracking_Code' => 'abc123',
        'object' => 'supporter'
      }
    end
    let(:api_response) do
      <<~XML
      <data>
        <success key="123">You did it!</success>
      </data>
      XML
    end

    it 'should call the API, stripping out Last_Modified and Date_Created' do
      expect(api_client).to receive(:post).with('/save', expected_data).and_return(api_response)

      subject.save(supporter.attributes.update({'object' => 'supporter'}))
    end
  end
end
