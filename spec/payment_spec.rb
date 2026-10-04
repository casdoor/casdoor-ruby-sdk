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

RSpec.describe 'Casdoor payment API', :integration do
  it 'adds, gets, updates and deletes a payment' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Payment')

    # Add a new object
    payment = Casdoor::Payment.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      products: ['casbin'],
      price: 10,
      currency: 'USD'
    )
    expect(Casdoor.add_payment(payment)).to be(true)

    # Get all objects, check if our added object is inside the list
    payments = Casdoor.get_payments
    expect(payments.map(&:name)).to include(name)

    # Get the object
    payment = Casdoor.get_payment(name)
    expect(payment.name).to eq(name)

    # Update the object
    payment.products = %w[casbin casdoor]
    expect(Casdoor.update_payment(payment)).to be(true)

    # Validate the update
    updated_payment = Casdoor.get_payment(name)
    expect(updated_payment.products).to eq(%w[casbin casdoor])

    # Delete the object
    expect(Casdoor.delete_payment(payment)).to be(true)

    # Validate the deletion
    deleted_payment = Casdoor.get_payment(name)
    expect(deleted_payment).to be_nil
  end
end
