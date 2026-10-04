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
  # Signing users out, the counterpart of logout.go of the Go SDK
  class Client
    # Signs the user out of all their sessions, and expires their tokens
    def logout(access_token)
      sso_logout(access_token, true)
    end

    # Signs the user out of only the session of the access token
    def logout_current_session(access_token)
      sso_logout(access_token, false)
    end

    private

    # The "/api/sso-logout" API identifies the user by their own access token, so the Bearer token is used instead of
    # the application's Basic Auth
    def sso_logout(access_token, logout_all)
      raise ArgumentError, 'logout() error: the access_token should not be empty' if access_token.to_s.empty?

      with_access_token(access_token).do_post('sso-logout', { 'logoutAll' => logout_all.to_s }, nil, true)
      true
    end
  end
end
