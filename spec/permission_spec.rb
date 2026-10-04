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

RSpec.describe 'Casdoor permission API', :integration do
  it 'adds, gets, updates and deletes a permission' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Permission')

    # Add a new object
    permission = Casdoor::Permission.new(
      owner: 'casbin',
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      description: 'Casdoor Website',
      users: ['casbin/*'],
      groups: [],
      roles: [],
      domains: [],
      model: 'admin/user-model-built-in',
      resource_type: 'Application',
      resources: ['app-casbin'],
      actions: %w[Read Write],
      effect: 'Allow',
      is_enabled: true
    )
    expect(Casdoor.add_permission(permission)).to be(true)

    # Get all objects, check if our added object is inside the list
    permissions = Casdoor.get_permissions
    expect(permissions.map(&:name)).to include(name)

    # Get the object
    permission = Casdoor.get_permission(name)
    expect(permission.name).to eq(name)

    # Update the object
    permission.description = 'Updated Casdoor Website'
    expect(Casdoor.update_permission(permission)).to be(true)

    # Validate the update
    updated_permission = Casdoor.get_permission(name)
    expect(updated_permission.description).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_permission(permission)).to be(true)

    # Validate the deletion
    deleted_permission = Casdoor.get_permission(name)
    expect(deleted_permission).to be_nil
  end
end
