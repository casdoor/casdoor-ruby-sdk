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
  class Plan < Entity; end

  # The plan APIs, the counterpart of plan.go of the Go SDK
  class Client
    def get_plans
      get_objects('get-plans', Plan, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_plans(page, page_size, query_map = {})
      get_pagination_objects('get-plans', Plan, organization_name, page, page_size, query_map)
    end

    def get_plan(name)
      get_object('get-plan', Plan, 'id' => get_id(name))
    end

    def update_plan(plan)
      modify_object('update-plan', Plan, plan, organization_name)
    end

    def add_plan(plan)
      modify_object('add-plan', Plan, plan, organization_name)
    end

    def delete_plan(plan)
      modify_object('delete-plan', Plan, plan, organization_name)
    end
  end
end
