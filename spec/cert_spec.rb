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

RSpec.describe 'Casdoor cert API', :integration do
  it 'adds, gets, updates and deletes a cert' do
    TestUtil.init_config

    name = TestUtil.get_random_name('cert')

    # Add a new object
    cert = Casdoor::Cert.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      scope: 'JWT',
      type: 'x509',
      crypto_algorithm: 'RS256',
      bit_size: 4096,
      expire_in_years: 20
    )
    expect(Casdoor.add_cert(cert)).to be(true)

    # Get all objects, check if our added object is inside the list
    certs = Casdoor.get_certs
    expect(certs.map(&:name)).to include(name)

    # Get the object
    cert = Casdoor.get_cert(name)
    expect(cert.name).to eq(name)

    # Update the object
    cert.display_name = 'Updated Casdoor Website'
    expect(Casdoor.update_cert(cert)).to be(true)

    # Validate the update
    updated_cert = Casdoor.get_cert(name)
    expect(updated_cert.display_name).to eq('Updated Casdoor Website')

    # Delete the object
    expect(Casdoor.delete_cert(cert)).to be(true)

    # Validate the deletion
    deleted_cert = Casdoor.get_cert(name)
    expect(deleted_cert).to be_nil
  end
end
