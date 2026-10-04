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
  class Session < Entity; end

  # The session APIs, the counterpart of session.go of the Go SDK
  class Client
    def get_sessions
      get_objects('get-sessions', Session, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_sessions(page, page_size, query_map = {})
      get_pagination_objects('get-sessions', Session, organization_name, page, page_size, query_map)
    end

    # A session is identified by its user and application
    def get_session(name, application)
      get_object('get-session', Session, 'sessionPkId' => "#{get_id(name)}/#{application}")
    end

    def update_session(session)
      modify_object('update-session', Session, session, organization_name)
    end

    def update_session_for_columns(session, columns)
      modify_object('update-session', Session, session, organization_name, columns)
    end

    def add_session(session)
      modify_object('add-session', Session, session, organization_name)
    end

    def delete_session(session)
      modify_object('delete-session', Session, session, organization_name)
    end
  end
end
