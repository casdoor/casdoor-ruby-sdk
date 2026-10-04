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

RSpec.describe 'Casdoor LDAP API', :integration do
  it 'adds, gets, updates and deletes an LDAP server of the organization' do
    TestUtil.init_config

    id = TestUtil.get_random_name('Ldap')

    # An LDAP server belongs to an organization, the synced users are added to it
    ldap = Casdoor::Ldap.new(
      id: id,
      created_time: Casdoor.get_current_time,
      server_name: 'Test LDAP Server',
      host: 'localhost',
      port: 389,
      username: 'cn=admin,dc=example,dc=com',
      password: 'password',
      base_dn: 'dc=example,dc=com'
    )
    expect(Casdoor.add_ldap(ldap)).to be(true)
    expect(ldap.owner).to eq(TestUtil::TEST_CASDOOR_ORGANIZATION)

    # Get all objects, check if our added object is inside the list
    expect(Casdoor.get_ldaps.map(&:id)).to include(id)

    # Get the object
    ldap = Casdoor.get_ldap(id)
    expect(ldap.id).to eq(id)

    # Update the object
    ldap.server_name = 'Updated LDAP Server'
    Casdoor.update_ldap(ldap)

    # Validate the update
    expect(Casdoor.get_ldap(id).server_name).to eq('Updated LDAP Server')

    # Delete the object
    expect(Casdoor.delete_ldap(ldap)).to be(true)

    # Validate the deletion
    expect(Casdoor.get_ldap(id)).to be_nil
  end

  it 'gets the names of the organizations owned by admin' do
    TestUtil.init_config

    expect(Casdoor.get_organization_names.map(&:name)).to include(TestUtil::TEST_CASDOOR_ORGANIZATION)
  end
end
