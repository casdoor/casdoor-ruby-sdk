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

RSpec.describe 'Casdoor session API', :integration do
  it 'adds, gets, updates and deletes a session' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Session')

    # Add a new object
    session = Casdoor::Session.new(
      owner: 'casbin',
      name: name,
      created_time: Casdoor.get_current_time,
      application: 'app-built-in',
      session_id: []
    )
    expect(Casdoor.add_session(session)).to be(true)

    # Get all objects, check if our added object is inside the list
    sessions = Casdoor.get_sessions
    expect(sessions.map(&:name)).to include(name)

    # Get the object
    session = Casdoor.get_session(name, session.application)
    expect(session.name).to eq(name)

    # Update the object
    update_time = (Time.now + 3600).iso8601
    session.created_time = update_time
    expect(Casdoor.update_session(session)).to be(true)

    # Validate the update
    updated_session = Casdoor.get_session(name, session.application)
    expect(updated_session.created_time).to eq(update_time)

    # Delete the object
    expect(Casdoor.delete_session(session)).to be(true)

    # Validate the deletion
    deleted_session = Casdoor.get_session(name, session.application)
    expect(deleted_session).to be_nil
  end
end
