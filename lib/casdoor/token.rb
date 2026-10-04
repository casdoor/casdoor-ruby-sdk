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
  class Token < Entity; end

  # The token APIs, the counterpart of token.go of the Go SDK
  class Client
    def get_tokens
      get_objects('get-tokens', Token, 'owner' => 'admin')
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_tokens(page, page_size, query_map = {})
      get_pagination_objects('get-tokens', Token, 'admin', page, page_size, query_map)
    end

    def get_token(name)
      get_object('get-token', Token, 'id' => get_admin_id(name))
    end

    def update_token(token)
      modify_object('update-token', Token, token, 'admin')
    end

    def update_token_for_columns(token, columns)
      modify_object('update-token', Token, token, 'admin', columns)
    end

    def add_token(token)
      modify_object('add-token', Token, token, 'admin')
    end

    def delete_token(token)
      modify_object('delete-token', Token, token, 'admin')
    end

    # Asks Casdoor whether the token is active, see RFC 7662. Returns a hash like
    # {"active" => true, "client_id" => "...", "username" => "alice", "exp" => 1700000000, ...}.
    def introspect_token(token, token_type_hint = 'access_token')
      request = Net::HTTP::Post.new(URI(get_url('login/oauth/introspect')))
      request.set_form_data('token' => token, 'token_type_hint' => token_type_hint)
      check_oauth_response(send_request(request))
    end
  end
end
