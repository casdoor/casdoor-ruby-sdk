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

RSpec.describe 'Casdoor syncer API', :integration do
  it 'adds, gets, updates and deletes a syncer' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Syncer')

    # Add a new object
    syncer = Casdoor::Syncer.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      organization: 'casbin',
      host: 'localhost',
      port: 3306,
      user: 'root',
      password: '123',
      database_type: 'mysql',
      database: 'syncer_db',
      table: 'user_table',
      sync_interval: 1
    )
    expect(Casdoor.add_syncer(syncer)).to be(true)

    # Get all objects, check if our added object is inside the list
    syncers = Casdoor.get_syncers
    expect(syncers.map(&:name)).to include(name)

    # Get the object
    syncer = Casdoor.get_syncer(name)
    expect(syncer.name).to eq(name)

    # Update the object
    syncer.host = 'Updated Host'
    expect(Casdoor.update_syncer(syncer)).to be(true)

    # Validate the update
    updated_syncer = Casdoor.get_syncer(name)
    expect(updated_syncer.host).to eq('Updated Host')

    # Delete the object
    expect(Casdoor.delete_syncer(syncer)).to be(true)

    # Validate the deletion
    deleted_syncer = Casdoor.get_syncer(name)
    expect(deleted_syncer).to be_nil
  end
end
