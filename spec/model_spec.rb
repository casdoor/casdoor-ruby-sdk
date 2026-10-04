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

RSpec.describe 'Casdoor model API', :integration do
  it 'adds, gets, updates and deletes a model' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Model')
    model_text = <<~MODEL
      [request_definition]
      r = sub, obj, act

      [policy_definition]
      p = sub, obj, act

      [role_definition]
      g = _, _

      [policy_effect]
      e = some(where (p.eft == allow))

      [matchers]
      m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act
    MODEL

    # Add a new object
    model = Casdoor::Model.new(
      owner: 'casbin',
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      model_text: model_text
    )
    expect(Casdoor.add_model(model)).to be(true)

    # Get all objects, check if our added object is inside the list
    models = Casdoor.get_models
    expect(models.map(&:name)).to include(name)

    # Get the object
    model = Casdoor.get_model(name)
    expect(model.name).to eq(name)

    # Update the object
    model.display_name = 'UpdatedName'
    expect(Casdoor.update_model(model)).to be(true)

    # Validate the update
    updated_model = Casdoor.get_model(name)
    expect(updated_model.display_name).to eq('UpdatedName')

    # Delete the object
    expect(Casdoor.delete_model(model)).to be(true)

    # Validate the deletion
    deleted_model = Casdoor.get_model(name)
    expect(deleted_model).to be_nil
  end
end
