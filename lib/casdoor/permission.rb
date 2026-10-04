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
  class Permission < Entity; end

  # The permission APIs, the counterpart of permission.go of the Go SDK
  class Client
    def get_permissions
      get_objects('get-permissions', Permission, 'owner' => organization_name)
    end

    # The permissions that the role is granted
    def get_permissions_by_role(name)
      get_objects('get-permissions-by-role', Permission, 'id' => get_id(name))
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_permissions(page, page_size, query_map = {})
      get_pagination_objects('get-permissions', Permission, organization_name, page, page_size, query_map)
    end

    def get_permission(name)
      get_object('get-permission', Permission, 'id' => get_id(name))
    end

    def update_permission(permission)
      modify_object('update-permission', Permission, permission, organization_name)
    end

    def update_permission_for_columns(permission, columns)
      modify_object('update-permission', Permission, permission, organization_name, columns)
    end

    def add_permission(permission)
      modify_object('add-permission', Permission, permission, organization_name)
    end

    def delete_permission(permission)
      modify_object('delete-permission', Permission, permission, organization_name)
    end
  end
end
