require 'net/http'

module Ezid

  class ApiSession

    VERSION = '0.2'
    APIVERSION = 'EZID API, Version 2'

    SECURESERVER = "https://n2t.net/ezid"
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

      @user = username
      @pass = password
      @scheme = SCHEMES[scheme]
      @naa = naa

      if @test == true
        @naa = TESTSHOULDER[@scheme]
      end
    end

    def mint(metadata={})
      shoulder = @scheme + @naa
      metadata['_status'] = PRIVATE
      #TODO: send mint request to API
      request_uri = "/shoulder/" + shoulder
      call_api(request_uri, :post, metadata)
    end

    def create(identifier, metadata={})
      if not metadata['_status']
        metadata['_status'] = PRIVATE
      end
      if not (identifier.start_with?(SCHEMES[:ark]) or identifier.start_with?(SCHEMES[:doi]))
        identifier = @scheme + @naa + identifier
      end
      request_uri = "/id/" + identifier
      call_api(request_uri, :put, metadata)
    end

    def modify(identifier, name, value)
      request_uri = "/id/" + identifier
      call_api(request_uri, :post, {name => value})
    end

    def get(identifier)
      request_uri = "/id/" + identifier
      call_api(request_uri, :get)
    end

    def delete(identifier)
      request_uri = "/id/" + identifier
      call_api(request_uri, :delete)
    end

    # public utility methods
    def change_profile(identifier, profile)
      modify(identifier, '_profile', profile)
    end

    def get_status(identifier)
      get(identifier)['metadata']['_status']
    end

    def make_public(identifier)
      modify(identifier, '_status', PUBLIC)
    end

    def make_unavailable(identifier)
      modify(identifier, '_status', UNAVAIL)
    end

    def get_target(identifier)
      get(identifier)['metadata']['_target']
    end

    def modify_target(identifier, target)
      modify(identifier, '_target', target)
    end

    def record_modify(identifier, metadata, clear=false)
      if clear
        #TODO: clear old metadata
      end
      metadata.each do |name, value|
        modify(identifier, name, value)
      end
      get(identifier)
    end

    def set_scheme(scheme)
      @scheme = scheme
    end

    def set_naa(naa)
      @naa = naa
    end
          
    private
    
    def call_api(request_uri, request_method, request_data=nil)
      uri = URI(SECURESERVER + request_uri)

      # which HTTP method to use?
      if request_method == :get
        request = Net::HTTP::Get.new uri.request_uri
      elsif request_method == :put
        request = Net::HTTP::Put.new uri.request_uri
        request.body = make_anvl(request_data)
      elsif request_method == :post
        request = Net::HTTP::Post.new uri.request_uri
        request.body = make_anvl(request_data)
      elsif request_method == :delete
        request = Net::HTTP::Delete.new uri.request_uri
      end
      
      request.basic_auth @user, @pass
      request.add_field("Content-Type", "text/plain; charset=UTF-8")

      # Make the call
      Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        parse_record http.request(request).body
      end
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
      #TODO: define escape method for anvl
      def escape(s)
        URI.escape(i, /[%:\n\r]/)
      end
      anvl = ''
      metadata.each do |n, v|
        anvl += escape(n) + ': ' + escape(v) + "\n"
      end
      #remove last newline. there is probably a really good way avoid adding it in the first place. if you know it, please fix.
      anvl.strip().encode!("UTF-8") 
    end

  end

end
