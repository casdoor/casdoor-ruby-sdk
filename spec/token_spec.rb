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

RSpec.describe 'Casdoor token API', :integration do
  it 'adds, gets, updates and deletes a token' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Token')

    # Add a new object
    token = Casdoor::Token.new(
      owner: 'admin',
      name: name,
      created_time: Casdoor.get_current_time,
      organization: 'casbin',
      code: 'abc',
      access_token: '123456'
    )
    expect(Casdoor.add_token(token)).to be(true)

    # Get all objects, check if our added object is inside the list
    tokens = Casdoor.get_tokens
    expect(tokens.map(&:name)).to include(name)

    # Get the object
    token = Casdoor.get_token(name)
    expect(token.name).to eq(name)

    # Update the object
    token.code = 'Updated Code'
    expect(Casdoor.update_token(token)).to be(true)

    # Validate the update
    updated_token = Casdoor.get_token(name)
    expect(updated_token.code).to eq('Updated Code')

    # Delete the object
    expect(Casdoor.delete_token(token)).to be(true)

    # Validate the deletion, Casdoor answers that the token doesn't exist
    begin
      deleted_token = Casdoor.get_token(name)
      expect(deleted_token).to be_nil
    rescue Casdoor::ApiError => e
      expect(e.message).to include('does not exist')
    end
  end
end
