require 'rest_client'
require 'uri'

module ezid

  class ApiSession

    VERSION = '0.2'
    APIVERSION = 'EZID API, Version 2'

    SECURESERVER = URI.parse("https://n2t.net/ezid")
    TESTUSERNAME = 'apitest'
    TESTPASSWORD = 'apitest'
    SCHEMES = {:ark => 'ark:/', :doi => "doi:"}

    PRIVATE = "reserved"
    PUBLIC = "public"
    UNAVAIL = "unavailable"
    TESTSHOULDER = {SCHEMES[:ark] => '99999/fk4', SCHEMES[:doi] => '10.5072/FK2'}
    TESTMETADATA = {'_target' => 'http://example.org/opensociety', 'erc.who' => 'Karl Poppe\
r', 'erc.what' => 'The Open Society and Its Enemies', 'erc.when' => '1945'}

    def initialize(username=TESTUSERNAME, password=TESTPASSWORD, scheme=:ark, naa='')
      if username == TESTUSERNAME
        password = TESTPASSWORD
        @test = true
      else
        @test = false
      end

      @username = username
      @pass = password
      @scheme = SCHEMES[scheme]
      @naa = naa

      
    end

    def mint(metadata={})
      shoulder = @scheme + @naa
      metadata['_status'] = PRIVATE
      #TODO: send mint request to API
      return false
    end

    def create(identifier, metadata={})
      if not metadata['_status']
        metadata['_status'] = PRIVATE
      end
      if not identifier.start_with?(SCHEMES[:ark]) or identifier.start_with(SCHEMES[:doi])
        identifier = @scheme + @naa + identifier
      end
      request_uri = SECURESERVER + "/id/" + identifier
      call_api(request_uri, :put, make_anvl(metadata))
    end

    def modify(identifier, name, value)

    end

    def get(identifier)
      request_uri = SECURESERVER + "/id/" + identifier
      call_api(request_uri, :get)
    end

    def delete(identifier)

    end

    def change_profile(identifier, profile)

    end

    def get_status(identifier)
      get(identifier)['metadata']['_status']
    end

    def get_target(identifier)
      get(identifier)['metadata']['_target']
    end

    private
    
    def call_api(request_uri, request_method, request_data=nil)
      if request_method == :get
        response = RestClient.get request_uri, :accept => :text
      elsif request_method == :post
        response = RestClient.post request_uri
      elsif request_method == :put
        response = RestClient.putrequest_uri
      elsif request_method == :delete
        response = RestClient.delete request_uri
      end
      parse_record response
    end

    def parse_record(ezid_response)
      parts = ezid_response.split("\n")
      identifier = parts[0].split(": ")[1]
      metadata = {}
      if parts.length > 1
        parts[1..-1].each do |p|
          pair = p.split(": ")
          metadata[pair[0]] = pair[1]
        end
        record = {'identifier' => identifier, 'metadata' => metadata}
      else 
        record = identifier
      end
      record
    end

    def make_anvl(metadata)
      #TODO: define anvl method
      ''
    end

  end

end
