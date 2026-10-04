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

RSpec.describe 'Casdoor product API', :integration do
  it 'adds, gets, updates and deletes a product, and places an order of it' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Product')
    owner = TestUtil::TEST_CASDOOR_ORGANIZATION

    # Add a new object
    product = Casdoor::Product.new(
      owner: owner,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      image: 'https://cdn.casbin.org/img/casdoor-logo_1185x256.png',
      description: 'Casdoor Website',
      tag: 'auto_created_product_for_plan',
      quantity: 999,
      sold: 0,
      state: 'Published',
      providers: ['provider_payment_dummy'],
      currency: 'USD'
    )
    expect(Casdoor.add_product(product)).to be(true)

    # Get all objects, check if our added object is inside the list
    products = Casdoor.get_products
    expect(products.map(&:name)).to include(name)

    # Get the object
    product = Casdoor.get_product(name)
    expect(product.name).to eq(name)

    # Update the object
    product.description = 'Updated Casdoor Website'
    expect(Casdoor.update_product(product)).to be(true)

    # Validate the update
    updated_product = Casdoor.get_product(name)
    expect(updated_product.description).to eq('Updated Casdoor Website')

    # Place an order of the product
    product_infos = [Casdoor::ProductInfo.new(name: name, quantity: 1)]
    order = Casdoor.place_order(product_infos, 'admin')
    expect(order.name).not_to be_empty

    # Delete the object
    expect(Casdoor.delete_product(product)).to be(true)

    # Validate the deletion
    deleted_product = Casdoor.get_product(name)
    expect(deleted_product).to be_nil
  end
end
