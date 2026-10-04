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

RSpec.describe 'Casdoor webhook API', :integration do
  it 'adds, gets, updates and deletes a webhook' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Webhook')

    # Add a new object
    webhook = Casdoor::Webhook.new(
      owner: 'casbin',
      name: name,
      created_time: Casdoor.get_current_time,
      organization: 'casbin'
    )
    expect(Casdoor.add_webhook(webhook)).to be(true)

    # Get all objects, check if our added object is inside the list
    webhooks = Casdoor.get_webhooks
    expect(webhooks.map(&:name)).to include(name)

    # Get the object
    webhook = Casdoor.get_webhook(name)
    expect(webhook.name).to eq(name)

    # Update the object
    webhook.organization = 'admin'
    expect(Casdoor.update_webhook(webhook)).to be(true)

    # Validate the update
    updated_webhook = Casdoor.get_webhook(name)
    expect(updated_webhook.organization).to eq('admin')

    # Delete the object
    expect(Casdoor.delete_webhook(webhook)).to be(true)

    # Validate the deletion
    deleted_webhook = Casdoor.get_webhook(name)
    expect(deleted_webhook).to be_nil
  end
end
