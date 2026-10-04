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

RSpec.describe 'Casdoor order pay API', :integration do
  it 'places and pays an order' do
    TestUtil.init_config

    name = TestUtil.get_random_name('OrderPayProduct')
    owner = TestUtil::TEST_CASDOOR_ORGANIZATION

    # Add a product to order
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

    # Place an order of the product
    product_infos = [Casdoor::ProductInfo.new(name: name, quantity: 1)]
    order = Casdoor.place_order(product_infos, 'admin')
    expect(order.name).not_to be_empty

    # Pay the order
    payment = Casdoor.pay_order(order.name, 'provider_payment_dummy')
    expect(payment).to be_a(Casdoor::Payment)

    # Delete the product
    expect(Casdoor.delete_product(product)).to be(true)
    expect(Casdoor.get_product(name)).to be_nil
  end

  it 'buys a product' do
    TestUtil.init_config

    name = TestUtil.get_random_name('BuyProduct')
    owner = TestUtil::TEST_CASDOOR_ORGANIZATION

    # Add a product to buy
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

    # Buy the product
    order = Casdoor.buy_product(name, 'provider_payment_dummy', 'admin')
    expect(order.name).not_to be_empty

    # Pay the order
    payment = Casdoor.pay_order(order.name, 'provider_payment_dummy')
    expect(payment).to be_a(Casdoor::Payment)

    # Delete the product
    expect(Casdoor.delete_product(product)).to be(true)
    expect(Casdoor.get_product(name)).to be_nil
  end
end
