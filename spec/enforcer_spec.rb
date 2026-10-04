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

RSpec.describe 'Casdoor enforcer API', :integration do
  it 'adds, gets, updates and deletes an enforcer' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Enforcer')

    # Add a new object
    enforcer = Casdoor::Enforcer.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      model: 'built-in/user-model-built-in',
      adapter: 'built-in/user-adapter-built-in',
      description: 'Casdoor Website'
    )
    expect(Casdoor.add_enforcer(enforcer)).to be(true)

    # Get all objects, check if our added object is inside the list
    enforcers = Casdoor.get_enforcers
    expect(enforcers.map(&:name)).to include(name)

    # Get the object
    enforcer = Casdoor.get_enforcer(name)
    expect(enforcer.name).to eq(name)

    # Update the object
    enforcer.description = 'Updated Casdoor Website'
    expect(Casdoor.update_enforcer(enforcer)).to be(true)

    # Validate the update
    updated_enforcer = Casdoor.get_enforcer(name)
    expect(updated_enforcer.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_enforcer(enforcer)).to be(true)

    # Validate the deletion
    deleted_enforcer = Casdoor.get_enforcer(name)
    expect(deleted_enforcer).to be_nil
  end
end
