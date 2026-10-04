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
  class Adapter < Entity; end

  # The adapter APIs, the counterpart of adapter.go of the Go SDK
  class Client
    def get_adapters
      get_objects('get-adapters', Adapter, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_adapters(page, page_size, query_map = {})
      get_pagination_objects('get-adapters', Adapter, organization_name, page, page_size, query_map)
    end

    def get_adapter(name)
      get_object('get-adapter', Adapter, 'id' => get_id(name))
    end

    def update_adapter(adapter)
      modify_object('update-adapter', Adapter, adapter, organization_name)
    end

    def add_adapter(adapter)
      modify_object('add-adapter', Adapter, adapter, organization_name)
    end

    def delete_adapter(adapter)
      modify_object('delete-adapter', Adapter, adapter, organization_name)
    end
  end
end
