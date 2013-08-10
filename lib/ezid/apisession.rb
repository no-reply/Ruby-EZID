# -*- coding: utf-8 -*-

require 'net/http'
require 'ezid/record'
require 'ezid/server_response'

module Ezid
  class ApiSession
    attr_accessor :naa, :username, :password
    attr_reader :scheme

    VERSION = '0.2.1'
    APIVERSION = 'EZID API, Version 2'

    SECURESERVER = 'https://n2t.net/ezid'
    TESTUSERNAME = 'apitest'
    TESTPASSWORD = 'apitest'
    SCHEMES = { :ark => 'ark:/', :doi => 'doi:' }

    PRIVATE = 'reserved'
    PUBLIC = 'public'
    UNAVAIL = 'unavailable'

    TESTSHOULDER = { SCHEMES[:ark] => '99999/fk4', SCHEMES[:doi] => '10.5072/FK2' }
    TESTMETADATA = { '_target' => 'http://example.org/opensociety',
      'erc.who' => 'Karl Popper',
      'erc.what' => 'The Open Society and Its Enemies',
      'erc.when' => '1945' }

    def initialize(username = TESTUSERNAME, password = TESTPASSWORD, scheme = :ark, naa = '')
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

      @naa = TESTSHOULDER[@scheme] if @test == true
      self
    end

    def mint(metadata = {})
      shoulder = @scheme + @naa
      metadata['_status'] = PRIVATE
      request_uri = "/shoulder/#{shoulder}"
      request = call_api(request_uri, :post, metadata)
      return request if request.errored?

      get(request)
    end

    def create(identifier, metadata = {})
      metadata = transform_metadata(metadata)
      request_uri = '/id/' + build_identifier(identifier)
      request = call_api(request_uri, :put, metadata)
      request.errored? ? request : get(request)
    end

    def transform_metadata(metadata)
      metadata['_status'] = PRIVATE unless metadata['_status']
      metadata
    end

    def build_identifier(identifier)
      unless identifier.start_with?(ApiSession::SCHEMES[:ark]) ||
          identifier.start_with?(ApiSession::SCHEMES[:doi])
        identifier = @scheme + @naa + identifier
      end
      identifier
    end

    def get(identifier)
      identifier = identifier.to_str
      identifier = identifier.split(' | ')[0] if identifier.include?('| ark:/')
      request_uri = '/id/' + identifier
      request = call_api(request_uri, :get)
      return request if request.errored?
      Ezid::Record.new(self, request.response['identifier'], request.response['metadata'], true)
    end

    def delete(identifier)
      request_uri = '/id/' + identifier
      call_api(request_uri, :delete)
    end

    # public utility methods

    def record_modify(identifier, metadata, clear = false)
      if clear
        # TODO: clear old metadata
      end
      metadata.each do |name, value|
        modify(identifier, name, value)
      end
      get(identifier)
    end

    def scheme=(scheme)
      @scheme = SCHEMES[scheme]
      @naa = TESTSHOULDER[@scheme] if @test == true
      @scheme
    end

    private

    def call_api(request_uri, request_method, request_data = nil)
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
      request.add_field('Content-Type', 'text/plain; charset=UTF-8')

      # Make the call
      result = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        parse_record http.request(request).body
      end
      Ezid::ServerResponse.new(result)
    end

    def parse_record(ezid_response)
      parts = ezid_response.split("\n")
      identifier = parts[0].split(': ')[1]
      metadata = {}
      if parts.length > 1
        parts[1..-1].each do |p|
          pair = p.split(': ')
          metadata[pair[0]] = pair[1]
        end
        record = { 'identifier' => identifier, 'metadata' => metadata }
      else
        record = identifier
      end
      record
    end

    def make_anvl(metadata)
      def escape(s)
        URI.escape(s, /[%:\n\r]/)
      end
      anvl = ''
      metadata.each do |n, v|
        anvl += escape(n.to_s) + ': ' + escape(v.to_s) + "\n"
      end
      # remove last newline. there is probably a really good way to
      # avoid adding it in the first place. if you know it, please fix.
      anvl.strip.encode!('UTF-8')
    end
  end
end
