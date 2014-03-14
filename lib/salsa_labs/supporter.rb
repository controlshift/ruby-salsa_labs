module SalsaLabs
  ##
  # Supporter represents a single member in the Salsa Labs CRM.
  # Standard field list from documentation at
  #   https://help.salsalabs.com/entries/21518315-Standard-supporter-fields-the-supporter-object-
  ##
  class Supporter < SalsaObject

    def supporter_key
      (attributes['supporter_key'] || 0).to_i
    end

    def chapter_key
      (attributes['chapter_key'] || 0).to_i
    end

    def title
      attributes['title']
    end

    def first_name
      attributes['first_name']
    end

    def mi
      attributes['mi']
    end

    def last_name
      attributes['last_name']
    end

    def suffix
      attributes['suffix']
    end

    def email
      attributes['email']
    end

    def receive_email
      #convert tinyint to bool
      (attributes['receive_email'] == '1')
    end

    def phone
      attributes['phone']
    end

    def street
      attributes['street']
    end

    def street_2
      attributes['street_2']
    end

    def city
      attributes['city']
    end

    def state
      attributes['state']
    end

    def zip
      attributes['zip']
    end

    def country
      attributes['country']
    end

    def source
      attributes['source']
    end

    def status
      attributes['status']
    end

    def self.fetch(filter_parameters = {}, credentials = {})
      SupportersFetcher.new(filter_parameters, credentials).fetch
    end
    end

  end
end