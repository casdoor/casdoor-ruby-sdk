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

require 'jwt'
require 'openssl'

module Casdoor
  module Api
    # Signing users in with OAuth 2.0 / OIDC, and verifying the JWT tokens issued by Casdoor.
    #
    # The OAuth tokens are returned as the hashes of the Casdoor token API, e.g.
    #   {"access_token" => "...", "id_token" => "...", "refresh_token" => "...", "token_type" => "Bearer",
    #    "expires_in" => 604800, "scope" => "read"}
    module Auth
      JWT_ALGORITHMS = %w[RS256 RS384 RS512 ES256 ES384 ES512 PS256 PS384 PS512].freeze

      # The URL of the sign-in page that the browser is redirected to. After signing in, Casdoor redirects back to
      # redirect_uri with "code" and "state" in the query, and the code is exchanged with get_oauth_token.
      def get_signin_url(redirect_uri, state: application_name, scope: 'read')
        query = { 'client_id' => client_id, 'response_type' => 'code', 'redirect_uri' => redirect_uri,
                  'scope' => scope, 'state' => state }
        "#{endpoint}/login/oauth/authorize?#{URI.encode_www_form(query)}"
      end

      # The URL of the sign-up page. Without redirect_uri, it's the plain sign-up page of the application, otherwise
      # the user is signed in and redirected back to redirect_uri like get_signin_url.
      def get_signup_url(redirect_uri = nil, state: application_name, scope: 'read')
        return "#{endpoint}/signup/#{application_name}" if redirect_uri.nil?

        url = get_signin_url(redirect_uri, state: state, scope: scope)
        url.sub('/login/oauth/authorize', '/signup/oauth/authorize')
      end

      def get_user_profile_url(user_name, access_token = nil)
        url = "#{endpoint}/users/#{organization_name}/#{user_name}"
        access_token ? "#{url}?#{URI.encode_www_form('access_token' => access_token)}" : url
      end

      def get_my_profile_url(access_token = nil)
        url = "#{endpoint}/account"
        access_token ? "#{url}?#{URI.encode_www_form('access_token' => access_token)}" : url
      end

      # Exchanges the code that Casdoor passed to the redirect URI for the OAuth tokens
      def get_oauth_token(code)
        request_oauth_token('authorization_code', 'code' => code)
      end

      def refresh_oauth_token(refresh_token, scope: nil)
        request_oauth_token('refresh_token', 'refresh_token' => refresh_token, 'scope' => scope)
      end

      # The "password" grant type, it must be enabled in the "Grant types" of the application in Casdoor.
      # username is the user's name in the application's organization, like "alice".
      def get_oauth_token_by_password(username, password)
        request_oauth_token('password', 'username' => username, 'password' => password)
      end

      # A token of the application itself, the "client_credentials" grant type must be enabled in the application
      def get_oauth_token_by_client_credentials
        request_oauth_token('client_credentials')
      end

      # Verifies a JWT token (the access token or the ID token) with the certificate of the client, and returns its
      # claims. The token must not be expired, and must be issued to this application: pass audience: to check a
      # different audience (e.g. the resource of RFC 8707), or audience: false to skip the check.
      #
      #   claims = client.parse_jwt_token(token["access_token"])
      #   claims.name          # => "alice"
      #   claims.owner         # => "casbin"
      #   claims.user          # => Casdoor::User
      def parse_jwt_token(token, audience: nil)
        # The expiration and the "not before" time are verified by default
        payload, = JWT.decode(token, jwt_public_key, true, algorithms: JWT_ALGORITHMS)
        check_audience(payload['aud'], audience) unless audience == false
        Claims.new(payload)
      rescue JWT::DecodeError => e
        raise InvalidTokenError, e.message
      end

      # Asks Casdoor whether the token is active, see RFC 7662. Returns a hash like {"active" => true, ...}.
      def introspect_token(token, token_type_hint: 'access_token')
        request = Net::HTTP::Post.new(get_url('login/oauth/introspect'))
        request.set_form_data('token' => token, 'token_type_hint' => token_type_hint)
        check_oauth_response(send_request(request))
      end

      # Signs the user out of Casdoor, from all their sessions or only the session of the access token
      def logout(access_token, all_sessions: true)
        with_access_token(access_token).post_form('sso-logout', { 'logoutAll' => all_sessions }, {})
        true
      end

      private

      def request_oauth_token(grant_type, params = {})
        form = { 'grant_type' => grant_type, 'client_id' => client_id, 'client_secret' => client_secret }
        form.merge!(params.compact)

        request = Net::HTTP::Post.new(get_url('login/oauth/access_token'))
        request.set_form_data(form)
        token = check_oauth_response(send_request(request, auth: false))

        # Older Casdoor versions put the error into the access token
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

      def jwt_public_key
        pem = certificate.to_s
        raise Error, 'The certificate of the client is required to parse JWT tokens' if pem.strip.empty?

        pem.include?('CERTIFICATE') ? OpenSSL::X509::Certificate.new(pem).public_key : OpenSSL::PKey.read(pem)
      end

      # Casdoor issues the tokens to the client ID, or to "<client ID>-org-<organization>" for shared applications
      def check_audience(aud, audience)
        auds = Array(aud)
        valid = if audience
                  auds.include?(audience)
                else
                  auds.any? { |item| item == client_id || item.to_s.start_with?("#{client_id}-org-") }
                end
        raise InvalidTokenError, "The token is issued to #{auds.inspect}, not this application" unless valid
      end
    end
  end
end
