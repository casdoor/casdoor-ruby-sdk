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

RSpec.describe 'Casdoor role API', :integration do
  it 'adds, gets, updates and deletes a role' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Role')

    # Add a new object
    role = Casdoor::Role.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      description: 'Casdoor Website'
    )
    expect(Casdoor.add_role(role)).to be(true)

    # Get all objects, check if our added object is inside the list
    roles = Casdoor.get_roles
    expect(roles.map(&:name)).to include(name)

    # Get the object
    role = Casdoor.get_role(name)
    expect(role.name).to eq(name)

    # Update the object
    role.description = 'Updated Casdoor Website'
    expect(Casdoor.update_role(role)).to be(true)

    # Validate the update
    updated_role = Casdoor.get_role(name)
    expect(updated_role.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_role(role)).to be(true)

    # Validate the deletion
    deleted_role = Casdoor.get_role(name)
    expect(deleted_role).to be_nil
  end
end
