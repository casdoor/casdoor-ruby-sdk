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

RSpec.describe 'Casdoor adapter API', :integration do
  it 'adds, gets, updates and deletes an adapter' do
    TestUtil.init_config

    name = TestUtil.get_random_name('adapter')

    # Add a new object
    adapter = Casdoor::Adapter.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      user: name,
      host: 'https://casdoor.org'
    )
    expect(Casdoor.add_adapter(adapter)).to be(true)

    # Get all objects, check if our added object is inside the list
    adapters = Casdoor.get_adapters
    expect(adapters.map(&:name)).to include(name)

    # Get the object
    adapter = Casdoor.get_adapter(name)
    expect(adapter.name).to eq(name)

    # Update the object
    adapter.user = 'Updated Casdoor Website'
    expect(Casdoor.update_adapter(adapter)).to be(true)

    # Validate the update
    updated_adapter = Casdoor.get_adapter(name)
    expect(updated_adapter.user).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_adapter(adapter)).to be(true)

    # Validate the deletion
    deleted_adapter = Casdoor.get_adapter(name)
    expect(deleted_adapter).to be_nil
  end
end
