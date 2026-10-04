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
  # Placing and paying orders, the counterpart of order_pay.go of the Go SDK
  class Client
    # Places an order of the products for the user (the name in the client's organization).
    # product_infos are like [ProductInfo.new(name: "product-1", quantity: 1)].
    def place_order(product_infos, user_name)
      query = { 'owner' => organization_name }
      query['userName'] = user_name unless user_name.to_s.empty?
      body = { 'productInfos' => product_infos.map { |info| to_entity(ProductInfo, info) } }
      Order.new(do_post('place-order', query, body)['data'])
    end

    # Pays the order with the payment provider, returns the payment
    def pay_order(order_name, provider_name)
      query = { 'id' => get_id(order_name), 'providerName' => provider_name }
      Payment.new(do_post('pay-order', query, '')['data'])
    end

    # Places an order of one product for the user, it's then paid with pay_order
    def buy_product(name, _provider_name, user_name)
      place_order([ProductInfo.new(name: name, quantity: 1)], user_name)
    end
  end
end
