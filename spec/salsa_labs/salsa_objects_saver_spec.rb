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
        'key' => '31337',
        'organization_key' => '1234',
        'chapter_key' => '90210',
        'title' => 'Mr.',
        'first_name' => 'John',
        'mi' => 'Jacob',
        'last_name' => 'Jingleheimer Schmidt',
        'suffix' => 'IV',
        'email' => 'johnjacob@example.com',
        'receive_email' => 1,
        'receive_phone_blasts' => false,
        'receive_phone_blasts_boolvalue' => false,
        'phone' => '1234567890',
        'street' => '123 Main St',
        'street_2' => 'Apt 404',
        'city' => 'Schnechtady',
        'state' => 'NY',
        'zip' => '12345',
        'private_zip_plus_4' => '1111',
        'country' => 'USA',
        'source' => 'rspec',
        'status' => 'Active',
        'source_details' => 'foo123',
        'source_tracking_code' => 'foo123',
        'tracking_code' => 'abc123',
        'date_created' => 'Fri Mar 14 2014 14:07:29 GMT-0400 (EDT)',
        'last_modified' => 'Fri Mar 14 2014 13:54:10 GMT-0400 (EDT)',
        'district' => 'N/A',
        'language_code' => 'eng',
        'salsa_deleted' => false,
        'salsa_deleted_boolvalue' => false,
        'text' => 'asdf',
        'some_custom_field' => 'foo'
      }
    end
    let(:supporter) { SalsaLabs::Supporter.new(attributes) }
    let(:expected_data) do
      {
        'supporter_KEY' => '31337',
        'chapter_KEY' => '90210',
        'Title' => 'Mr.',
        'First_Name' => 'John',
        'MI' => 'Jacob',
        'Last_Name' => 'Jingleheimer Schmidt',
        'Suffix' => 'IV',
        'Email' => 'johnjacob@example.com',
        'Receive_Email' => 1,
        'Receive_Phone_Blasts' => 0,
        'Phone' => '1234567890',
        'Street' => '123 Main St',
        'Street_2' => 'Apt 404',
        'City' => 'Schnechtady',
        'State' => 'NY',
        'Zip' => '12345',
        'PRIVATE_Zip_Plus_4' => '1111',
        'District' => 'N/A',
        'Country' => 'USA',
        'Language_Code' => 'eng',
        'Source' => 'rspec',
        'Status' => 'Active',
        'Source_Details' => 'foo123',
        'Source_Tracking_Code' => 'foo123',
        'Tracking_Code' => 'abc123',
        'object' => 'supporter',
        'key' => '31337',
        'text' => 'asdf',
        'some_custom_field' => 'foo'
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
      expect(api_client).to receive(:post) do |endpoint, params|
        expect(endpoint).to eq '/save'
        expect(params).to eq expected_data

        # 'object' and 'key' fields must come first
        expect(params.keys.first).to eq 'object'
        expect(params.keys[1]).to eq 'key'
      end.and_return(api_response)

      subject.save(supporter.attributes.update({'object' => 'supporter'}))
    end
  end
end
