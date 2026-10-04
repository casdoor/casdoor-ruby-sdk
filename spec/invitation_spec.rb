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

RSpec.describe 'Casdoor invitation API', :integration do
  it 'adds, gets, updates and deletes an invitation' do
    TestUtil.init_config

    name = TestUtil.get_random_name('unit_test_invitation')
    code = "TEST#{TestUtil.get_random_code(6)}"

    # Add a new object
    invitation = Casdoor::Invitation.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: 'Test Invitation',
      code: code,
      default_code: code,
      quota: 10,
      used_count: 0,
      application: TestUtil::TEST_CASDOOR_APPLICATION,
      email: 'test@example.com',
      signup_group: 'test-group',
      state: 'Active'
    )
    expect(Casdoor.add_invitation(invitation)).to be(true)

    # Get the object
    invitation2 = Casdoor.get_invitation(name)
    expect(invitation2.code).to eq(code)

    # Get all objects
    invitations = Casdoor.get_invitations
    expect(invitations.map(&:name)).to include(name)

    # Update the object
    invitation2.state = 'Suspended'
    expect(Casdoor.update_invitation(invitation2)).to be(true)
    expect(Casdoor.get_invitation(name).state).to eq('Suspended')

    invitation2.state = 'Active'
    expect(Casdoor.update_invitation(invitation2)).to be(true)

    # Get the invitation by its code
    invitation = Casdoor.get_invitation_info(code, 'app-casbin')
    expect(invitation).not_to be_nil

    # Delete the object
    expect(Casdoor.delete_invitation(invitation2)).to be(true)

    # Validate the deletion
    deleted_invitation = Casdoor.get_invitation(name)
    expect(deleted_invitation).to be_nil
  end
end
