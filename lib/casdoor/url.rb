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
  # The URLs of the Casdoor pages, the counterpart of url.go of the Go SDK
  class Client
    # The sign-up page. With enable_password, it's the plain sign-up page of the application and redirect_uri can be
    # empty; otherwise the user is signed in after signing up and redirected back to redirect_uri like
    # get_signin_url.
    def get_signup_url(enable_password, redirect_uri)
      return "#{endpoint}/signup/#{application_name}" if enable_password

      get_signin_url(redirect_uri).sub('/login/oauth/authorize', '/signup/oauth/authorize')
    end

    # The sign-in page that the browser is redirected to. After signing in, Casdoor redirects back to redirect_uri
    # with "code" and "state" in the query, and the code is exchanged with get_oauth_token.
    def get_signin_url(redirect_uri, state: application_name, scope: 'read')
      query = { 'client_id' => client_id, 'response_type' => 'code', 'redirect_uri' => redirect_uri,
                'scope' => scope, 'state' => state }
      "#{endpoint}/login/oauth/authorize?#{URI.encode_www_form(query)}"
    end

    def get_user_profile_url(user_name, access_token = '')
      url = "#{endpoint}/users/#{organization_name}/#{user_name}"
      access_token.to_s.empty? ? url : "#{url}?#{URI.encode_www_form('access_token' => access_token)}"
    end

    def get_my_profile_url(access_token = '')
      url = "#{endpoint}/account"
      access_token.to_s.empty? ? url : "#{url}?#{URI.encode_www_form('access_token' => access_token)}"
    end
  end
end
