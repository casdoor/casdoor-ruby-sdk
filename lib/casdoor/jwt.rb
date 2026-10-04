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
  # The claims of a JWT token issued by Casdoor: the fields of the user, plus the standard claims like "exp" and "aud"
  class Claims < Entity
    def user
      User.new(to_h)
    end

    # Casdoor names the claim "tokenType" for the JWT, JWT-Empty and JWT-Standard formats, and "TokenType" for
    # JWT-Custom
    def refresh_token?
      (self['tokenType'] || self['TokenType']) == 'refresh-token'
    end
  end

  # Verifying the JWT tokens, the counterpart of jwt.go of the Go SDK
  class Client
    JWT_ALGORITHMS = %w[RS256 RS384 RS512 ES256 ES384 ES512 PS256 PS384 PS512].freeze

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

    private

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
