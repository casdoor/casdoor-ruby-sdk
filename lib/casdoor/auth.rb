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

module Casdoor
  # The core configuration. The first step to use this SDK is to create a Client with it, or to initialize the global
  # client with Casdoor.init_config.
  AuthConfig = Struct.new(:endpoint, :client_id, :client_secret, :certificate, :organization_name,
                          :application_name, keyword_init: true)

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
    attr_reader :endpoint, :client_id, :client_secret, :certificate, :organization_name, :application_name,
                :access_token
    # Headers added to all the requests, e.g. to pass a gateway
    attr_accessor :custom_headers, :open_timeout, :read_timeout

    # certificate is the public certificate (or public key) of the application's cert in Casdoor, in PEM format.
    # It's only needed by parse_jwt_token.
    def initialize(endpoint:, client_id:, client_secret:, organization_name:, application_name:, certificate: nil,
                   custom_headers: {}, access_token: nil, open_timeout: 10, read_timeout: 30)
      @endpoint = endpoint.to_s.chomp('/')
      @client_id = client_id
      @client_secret = client_secret
      @certificate = certificate
      @organization_name = organization_name
      @application_name = application_name
      @custom_headers = custom_headers.dup
      @access_token = access_token
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def auth_config
      AuthConfig.new(endpoint: endpoint, client_id: client_id, client_secret: client_secret, certificate: certificate,
                     organization_name: organization_name, application_name: application_name)
    end

    # Returns a copy of the client that calls the API as the user who owns the access token, instead of as the
    # application. The access token is the user's OAuth access token returned by get_oauth_token,
    # refresh_oauth_token, get_oauth_token_by_password or impersonate_user. The original client keeps using the
    # client ID and secret, so it's safe to create one client per user request:
    #
    #   token = client.get_oauth_token(code, state)
    #   user = client.with_access_token(token["access_token"]).get_account
    #
    # The APIs are still subject to the permission check of Casdoor, so a normal user can only access their own data.
    def with_access_token(access_token)
      Client.new(endpoint: endpoint, client_id: client_id, client_secret: client_secret,
                 organization_name: organization_name, application_name: application_name, certificate: certificate,
                 custom_headers: custom_headers, access_token: access_token, open_timeout: open_timeout,
                 read_timeout: read_timeout)
    end

    # Exchanges the code that Casdoor passed to the redirect URI for the OAuth tokens. Returns the hash of the token
    # API, like {"access_token" => "...", "id_token" => "...", "refresh_token" => "...", "token_type" => "Bearer",
    # "expires_in" => 604800, "scope" => "read"}.
    def get_oauth_token(code, _state = nil)
      request_oauth_token('authorization_code', 'code' => code)
    end

    def refresh_oauth_token(refresh_token)
      request_oauth_token('refresh_token', 'refresh_token' => refresh_token)
    end

    # Gets the OAuth token via the "password" grant type, i.e. the "Resource Owner Password Credentials Grant" of
    # OAuth 2.0. The "password" grant type must be enabled in the application's "Grant types" in Casdoor.
    # The username is the user's name inside the application's organization, like "alice" instead of "my-org/alice".
    def get_oauth_token_by_password(username, password)
      request_oauth_token('password', 'username' => username, 'password' => password)
    end

    # Gets an OAuth token which acts as the given user, so that an admin can call the APIs on behalf of the user,
    # without knowing the user's own password. It's the SDK equivalent of the "Impersonation" button in Casdoor.
    # The master_password is the "Master password" of the user's organization, it needs to be set in Casdoor first:
    # "Organizations" -> Edit the organization -> "Master password". See: https://casdoor.ai/docs/user/impersonation
    def impersonate_user(username, master_password)
      get_oauth_token_by_password(username, master_password)
    end

    private

    def request_oauth_token(grant_type, params)
      form = { 'grant_type' => grant_type, 'client_id' => client_id, 'client_secret' => client_secret }.merge(params)
      request = Net::HTTP::Post.new(URI(get_url('login/oauth/access_token')))
      request.set_form_data(form)
      token = check_oauth_response(send_request(request, auth: false))

      # Older Casdoor versions put the error into the access token, like "error: invalid client_id"
      if token['access_token'].to_s.start_with?('error:')
        raise ApiError, token['access_token'].delete_prefix('error:').strip
      end

      token
    end

    def check_oauth_response(body)
      if body['error']
        message = [body['error'], body['error_description']].compact.reject(&:empty?).join(': ')
        raise ApiError, message
      end

      check_response(body)
    end
  end

  # The global client used by the module functions like Casdoor.get_users, see global.rb
  def self.init_config(endpoint, client_id, client_secret, certificate, organization_name, application_name)
    @global_client = new_client(endpoint, client_id, client_secret, certificate, organization_name, application_name)
  end

  def self.new_client(endpoint, client_id, client_secret, certificate, organization_name, application_name)
    new_client_with_conf(AuthConfig.new(endpoint: endpoint, client_id: client_id, client_secret: client_secret,
                                        certificate: certificate, organization_name: organization_name,
                                        application_name: application_name))
  end

  def self.new_client_with_conf(config)
    Client.new(**config.to_h)
  end
end
