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

RSpec.describe 'Casdoor plan API', :integration do
  it 'adds, gets, updates and deletes a plan' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Plan')

    # Add a new object
    plan = Casdoor::Plan.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      description: 'Casdoor Website',
      currency: 'USD'
    )
    expect(Casdoor.add_plan(plan)).to be(true)

    # Get all objects, check if our added object is inside the list
    plans = Casdoor.get_plans
    expect(plans.map(&:name)).to include(name)

    # Get the object
    plan = Casdoor.get_plan(name)
    expect(plan.name).to eq(name)

    # Update the object
    plan.description = 'Updated Casdoor Website'
    expect(Casdoor.update_plan(plan)).to be(true)

    # Validate the update
    updated_plan = Casdoor.get_plan(name)
    expect(updated_plan.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_plan(plan)).to be(true)

    # Validate the deletion
    deleted_plan = Casdoor.get_plan(name)
    expect(deleted_plan).to be_nil
  end
end
