# frozen_string_literal: true

# Copyright 2026 The Casdoor Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'net/http'
require 'uri'

module Casdoor
  # The client of the Casdoor API. By default it calls the API as the application, authenticated by the client ID
  # and the client secret. Use with_access_token to call the API as a user instead.
  #
  #   client = Casdoor::Client.new(
  #     endpoint: "https://door.casdoor.com",
  #     client_id: "...",
  #     client_secret: "...",
  #     certificate: File.read("token_jwt_key.pem"),
  #     organization_name: "casbin",
  #     application_name: "app-example"
  #   )
  class Client
    include Api::Auth
    include Api::Crud
    include Api::Users
    include Api::Enforce

    attr_reader :endpoint, :client_id, :client_secret, :certificate, :organization_name, :application_name,
                :access_token, :headers, :open_timeout, :read_timeout

    # certificate is the public certificate (or public key) of the application's cert in Casdoor, in PEM format.
    # It's only needed by parse_jwt_token.
    # headers are added to all the requests, e.g. to pass a gateway.
    def initialize(endpoint:, client_id:, client_secret:, organization_name:, application_name:, certificate: nil,
                   headers: {}, access_token: nil, open_timeout: 10, read_timeout: 30)
      @endpoint = endpoint.to_s.chomp('/')
      @client_id = client_id
      @client_secret = client_secret
      @certificate = certificate
      @organization_name = organization_name
      @application_name = application_name
      @headers = headers.dup.freeze
      @access_token = access_token
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    # Returns a copy of the client that calls the API as the user who owns the access token, instead of as the
    # application. The API is still subject to the permission check of Casdoor, so a normal user can only access
    # their own data:
    #
    #   token = client.get_oauth_token(code)
    #   user = client.with_access_token(token["access_token"]).get_account
    def with_access_token(access_token)
      Client.new(endpoint: endpoint, client_id: client_id, client_secret: client_secret,
                 organization_name: organization_name, application_name: application_name, certificate: certificate,
                 headers: headers, access_token: access_token, open_timeout: open_timeout, read_timeout: read_timeout)
    end

    def get_url(action, query = {})
      query = query.compact
      url = "#{endpoint}/api/#{action}"
      url += "?#{URI.encode_www_form(query)}" unless query.empty?
      URI(url)
    end

    # Calls a GET API, and returns the whole response like {"status" => "ok", "data" => ..., "data2" => ...}
    def get_response(action, query = {})
      request = Net::HTTP::Get.new(get_url(action, query))
      check_response(send_request(request))
    end

    # Calls a GET API, and returns the "data" of the response
    def get_data(action, query = {})
      get_response(action, query)['data']
    end

    # Calls a POST API with a JSON body, and returns the whole response
    def post_json(action, query, body)
      request = Net::HTTP::Post.new(get_url(action, query), 'Content-Type' => 'application/json')
      request.body = body.to_json
      check_response(send_request(request))
    end

    # Calls a POST API with a form body, and returns the whole response
    def post_form(action, query, form)
      request = Net::HTTP::Post.new(get_url(action, query))
      request.set_form_data(form)
      check_response(send_request(request))
    end

    private

    # Sends the request and returns the parsed JSON body. Errors of the HTTP layer are raised, while the
    # {"status": "error"} responses are left to the caller.
    def send_request(request, auth: true)
      if auth
        if access_token
          request['Authorization'] = "Bearer #{access_token}"
        else
          request.basic_auth(client_id.to_s, client_secret.to_s)
        end
      end
      request['Accept'] = 'application/json'
      headers.each { |key, value| request[key] = value }

      uri = request.uri
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                     open_timeout: open_timeout, read_timeout: read_timeout) do |http|
        http.request(request)
      end

      begin
        body = JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        raise HttpError.new(response.code.to_i, response.body)
      end

      return body if response.is_a?(Net::HTTPSuccess)
      # Casdoor answers some errors with a non-2xx status and a JSON body that explains the error
      return body if body.is_a?(Hash) && (body['status'] == 'error' || body['error'])

      raise HttpError.new(response.code.to_i, response.body)
    end

    def check_response(body)
      raise ApiError, body['msg'].to_s if body.is_a?(Hash) && body['status'] == 'error'

      body
    end
  end
end
