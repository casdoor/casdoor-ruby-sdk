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

RSpec.describe 'Casdoor order API', :integration do
  it 'adds, gets, updates, cancels and deletes an order' do
    TestUtil.init_config

    product_name = TestUtil.get_random_name('OrderProduct')
    order_name = TestUtil.get_random_name('Order')
    owner = TestUtil::TEST_CASDOOR_ORGANIZATION

    # Add a product to order
    product = Casdoor::Product.new(
      owner: owner,
      name: product_name,
      created_time: Casdoor.get_current_time,
      display_name: product_name,
      image: 'https://cdn.casbin.org/img/casdoor-logo_1185x256.png',
      description: 'Casdoor Website',
      tag: 'auto_created_product_for_plan',
      quantity: 999,
      sold: 0,
      state: 'Published',
      providers: ['provider_payment_dummy'],
      price: 1,
      currency: 'USD'
    )
    expect(Casdoor.add_product(product)).to be(true)

    # Add a new object
    order = Casdoor::Order.new(
      owner: owner,
      name: order_name,
      created_time: Casdoor.get_current_time,
      display_name: order_name,
      products: [product_name],
      product_infos: [
        Casdoor::ProductInfo.new(owner: owner, name: product_name, display_name: product_name, price: 1,
                                 currency: 'USD', quantity: 1)
      ],
      user: owner,
      price: 1,
      currency: 'USD',
      state: 'Created',
      message: ''
    )
    expect(Casdoor.add_order(order)).to be(true)

    # Get all objects, check if our added object is inside the list
    orders = Casdoor.get_orders
    expect(orders.map(&:name)).to include(order_name)

    # Get the orders of the user
    user_orders = Casdoor.get_user_orders(owner)
    expect(user_orders.map(&:name)).to include(order_name)

    # Get the object
    order = Casdoor.get_order(order_name)
    expect(order.name).to eq(order_name)

    # Update the object
    order.message = 'Updated order message'
    expect(Casdoor.update_order(order)).to be(true)

    # Validate the update
    updated_order = Casdoor.get_order(order_name)
    expect(updated_order.message).to eq('Updated order message')

    # Cancel the order
    expect(Casdoor.cancel_order(order_name)).to be(true)

    # Delete the object
    expect(Casdoor.delete_order(order)).to be(true)

    # Validate the deletion
    expect(Casdoor.get_order(order_name)).to be_nil

    # Delete the product
    expect(Casdoor.delete_product(product)).to be(true)
    expect(Casdoor.get_product(product_name)).to be_nil
  end
end
