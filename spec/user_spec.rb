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

RSpec.describe 'Casdoor user API', :integration do
  it 'adds, gets, updates and deletes an user' do
    TestUtil.init_config

    name = TestUtil.get_random_name('User')

    # Add a new object
    user = Casdoor::User.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name
    )
    expect(Casdoor.add_user(user)).to be(true)

    # Get all objects, check if our added object is inside the list
    users = Casdoor.get_users
    expect(users.map(&:name)).to include(name)

    # Get the object
    user = Casdoor.get_user(name)
    expect(user.name).to eq(name)

    # Update the object
    user.display_name = 'Updated Casdoor Website'
    expect(Casdoor.update_user(user)).to be(true)

    # Validate the update
    updated_user = Casdoor.get_user(name)
    expect(updated_user.display_name).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_user(user)).to be(true)

    # Validate the deletion
    deleted_user = Casdoor.get_user(name)
    expect(deleted_user).to be_nil
  end
end
