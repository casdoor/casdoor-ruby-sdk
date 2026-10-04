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

RSpec.describe 'Casdoor record API', :integration do
  it 'adds a record and reads it back as an admin user' do
    client = TestUtil.init_config
    name = TestUtil.get_random_name('Record')

    # Add a new object
    record = Casdoor::Record.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      organization: TestUtil::TEST_CASDOOR_ORGANIZATION,
      user: 'admin',
      action: 'test-record'
    )
    Casdoor.add_record(record)

    # Reading the records needs the access token of an admin user
    token = client.get_oauth_token_by_password('admin', '123')
    admin_client = client.with_access_token(token['access_token'])

    # Get all objects, check if our added object is inside the list
    expect(admin_client.get_records.map(&:name)).to include(name)

    # Get the object
    expect(admin_client.get_record(name).name).to eq(name)

    # Get an object that doesn't exist
    expect(admin_client.get_record("#{name}_missing")).to be_nil
  end
end
