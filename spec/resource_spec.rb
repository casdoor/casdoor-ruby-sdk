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

RSpec.describe 'Casdoor resource API', :integration do
  it 'uploads, gets and deletes a resource' do
    TestUtil.init_config

    # Upload a file of this SDK
    filename = 'resource.rb'
    data = File.binread(File.expand_path("../lib/casdoor/#{filename}", __dir__))
    name = "/casdoor/#{filename}"
    resource = Casdoor::Resource.new(
      owner: 'casbin',
      name: name,
      created_time: Casdoor.get_current_time,
      description: 'Casdoor Website',
      user: 'casbin',
      file_name: filename,
      file_size: data.bytesize,
      tag: name
    )
    file_url, = Casdoor.upload_resource(resource.user, resource.tag, '', resource.file_name, data)
    expect(file_url).not_to be_empty

    # Get all objects, check if our uploaded object is inside the list
    resources = Casdoor.get_resources(resource.owner, resource.user, '', '', '', '')
    expect(resources.map(&:tag)).to include(name)

    # Get the object
    resource = Casdoor.get_resource(resource.get_id)
    expect(resource.tag).to eq(name)

    # Delete the object
    expect(Casdoor.delete_resource(resource)).to be(true)

    # Validate the deletion
    deleted_resource = Casdoor.get_resource(resource.get_id)
    expect(deleted_resource).to be_nil
  end
end
