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

RSpec.describe 'Casdoor subscription API', :integration do
  it 'adds, gets, updates and deletes a subscription' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Subscription')

    # Add a new object
    subscription = Casdoor::Subscription.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      description: 'Casdoor Website'
    )
    expect(Casdoor.add_subscription(subscription)).to be(true)

    # Get all objects, check if our added object is inside the list
    subscriptions = Casdoor.get_subscriptions
    expect(subscriptions.map(&:name)).to include(name)

    # Get the object
    subscription = Casdoor.get_subscription(name)
    expect(subscription.name).to eq(name)

    # Update the object
    subscription.description = 'Updated Casdoor Website'
    expect(Casdoor.update_subscription(subscription)).to be(true)

    # Validate the update
    updated_subscription = Casdoor.get_subscription(name)
    expect(updated_subscription.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_subscription(subscription)).to be(true)

    # Validate the deletion
    deleted_subscription = Casdoor.get_subscription(name)
    expect(deleted_subscription).to be_nil
  end
end
