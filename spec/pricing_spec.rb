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

RSpec.describe 'Casdoor pricing API', :integration do
  it 'adds, gets, updates and deletes a pricing' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Pricing')

    # Add a new object
    pricing = Casdoor::Pricing.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      application: 'app-admin',
      description: 'Casdoor Website'
    )
    expect(Casdoor.add_pricing(pricing)).to be(true)

    # Get all objects, check if our added object is inside the list
    pricings = Casdoor.get_pricings
    expect(pricings.map(&:name)).to include(name)

    # Get the object
    pricing = Casdoor.get_pricing(name)
    expect(pricing.name).to eq(name)

    # Update the object
    pricing.description = 'Updated Casdoor Website'
    expect(Casdoor.update_pricing(pricing)).to be(true)

    # Validate the update
    updated_pricing = Casdoor.get_pricing(name)
    expect(updated_pricing.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_pricing(pricing)).to be(true)

    # Validate the deletion
    deleted_pricing = Casdoor.get_pricing(name)
    expect(deleted_pricing).to be_nil
  end
end
