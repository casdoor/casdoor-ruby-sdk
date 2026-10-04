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

RSpec.describe 'Casdoor organization API', :integration do
  it 'adds, gets, updates and deletes an organization' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Organization')

    # Add a new object
    organization = Casdoor::Organization.new(
      owner: 'admin',
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      website_url: 'https://example.com',
      password_type: 'plain',
      password_options: ['AtLeast6'],
      country_codes: %w[US ES FR DE GB CN JP KR VN ID SG IN],
      tags: [],
      languages: %w[en zh es fr de id ja ko ru vi pt],
      init_score: 2000,
      enable_soft_deletion: false,
      is_profile_public: false
    )
    expect(Casdoor.add_organization(organization)).to be(true)

    # Get all objects, check if our added object is inside the list
    organizations = Casdoor.get_organizations
    expect(organizations.map(&:name)).to include(name)

    # Get the object
    organization = Casdoor.get_organization(name)
    expect(organization.name).to eq(name)

    # Update the object
    organization.display_name = 'Updated Casdoor Website'
    expect(Casdoor.update_organization(organization)).to be(true)

    # Validate the update
    updated_organization = Casdoor.get_organization(name)
    expect(updated_organization.display_name).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_organization(organization)).to be(true)

    # Validate the deletion
    deleted_organization = Casdoor.get_organization(name)
    expect(deleted_organization).to be_nil
  end
end
