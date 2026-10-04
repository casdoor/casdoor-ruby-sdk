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
  class Enforcer < Entity; end

  # The enforcer APIs, the counterpart of enforcer.go of the Go SDK
  class Client
    def get_enforcers
      get_objects('get-enforcers', Enforcer, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_enforcers(page, page_size, query_map = {})
      get_pagination_objects('get-enforcers', Enforcer, organization_name, page, page_size, query_map)
    end

    def get_enforcer(name)
      get_object('get-enforcer', Enforcer, 'id' => get_id(name))
    end

    def update_enforcer(enforcer)
      modify_object('update-enforcer', Enforcer, enforcer, organization_name)
    end

    def add_enforcer(enforcer)
      modify_object('add-enforcer', Enforcer, enforcer, organization_name)
    end

    def delete_enforcer(enforcer)
      modify_object('delete-enforcer', Enforcer, enforcer, organization_name)
    end
  end
end
