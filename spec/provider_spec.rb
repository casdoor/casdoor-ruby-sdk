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

RSpec.describe 'Casdoor provider API', :integration do
  it 'adds, gets, updates and deletes a provider' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Provider')

    # Add a new object
    provider = Casdoor::Provider.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      category: 'Captcha',
      type: 'Default'
    )
    expect(Casdoor.add_provider(provider)).to be(true)

    # Get all objects, check if our added object is inside the list
    providers = Casdoor.get_providers
    expect(providers.map(&:name)).to include(name)

    # Get the object
    provider = Casdoor.get_provider(name)
    expect(provider.name).to eq(name)

    # Update the object
    provider.display_name = 'Updated Casdoor Website'
    expect(Casdoor.update_provider(provider)).to be(true)

    # Validate the update
    updated_provider = Casdoor.get_provider(name)
    expect(updated_provider.display_name).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_provider(provider)).to be(true)

    # Validate the deletion
    deleted_provider = Casdoor.get_provider(name)
    expect(deleted_provider).to be_nil
  end
end
