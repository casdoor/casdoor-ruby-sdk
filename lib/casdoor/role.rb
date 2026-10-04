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
  class Role < Entity; end

  # The role APIs, the counterpart of role.go of the Go SDK
  class Client
    def get_roles
      get_objects('get-roles', Role, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_roles(page, page_size, query_map = {})
      get_pagination_objects('get-roles', Role, organization_name, page, page_size, query_map)
    end

    def get_role(name)
      get_object('get-role', Role, 'id' => get_id(name))
    end

    def update_role(role)
      modify_object('update-role', Role, role, organization_name)
    end

    def update_role_for_columns(role, columns)
      modify_object('update-role', Role, role, organization_name, columns)
    end

    def add_role(role)
      modify_object('add-role', Role, role, organization_name)
    end

    def delete_role(role)
      modify_object('delete-role', Role, role, organization_name)
    end
  end
end
