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
  class Order < Entity; end

  # A product in an order, e.g. ProductInfo.new(name: "product-1", quantity: 1)
  class ProductInfo < Entity; end

  # The order APIs, the counterpart of order.go of the Go SDK
  class Client
    def get_orders
      get_objects('get-orders', Order, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_orders(page, page_size, query_map = {})
      get_pagination_objects('get-orders', Order, organization_name, page, page_size, query_map)
    end

    def get_user_orders(user_name)
      get_objects('get-user-orders', Order, 'owner' => organization_name, 'user' => user_name)
    end

    def get_order(name)
      get_object('get-order', Order, 'id' => get_id(name))
    end

    def update_order(order)
      modify_object('update-order', Order, order, organization_name)
    end

    def add_order(order)
      modify_object('add-order', Order, order, organization_name)
    end

    def delete_order(order)
      modify_object('delete-order', Order, order, organization_name)
    end

    def cancel_order(name)
      do_post('cancel-order', { 'id' => get_id(name) }, '')['data'] == 'Affected'
    end
  end
end
