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

RSpec.describe 'Casdoor enforce API', :integration do
  it 'enforces the policies of an enforcer' do
    TestUtil.init_config

    # Add a model
    model_name = TestUtil.get_random_name('enforceModel')
    model_text = <<~MODEL
      [request_definition]
      r = sub, obj, act

      [policy_definition]
      p = sub, obj, act

      [policy_effect]
      e = some(where (p.eft == allow))

      [matchers]
      m = r.sub == p.sub && r.obj == p.obj && r.act == p.act
    MODEL
    model = Casdoor::Model.new(owner: 'casbin', name: model_name, display_name: model_name, model_text: model_text)
    expect(Casdoor.add_model(model)).to be(true)

    # Add an adapter
    adapter_name = TestUtil.get_random_name('enforceAdapter')
    adapter = Casdoor::Adapter.new(owner: 'casbin', name: adapter_name, table: "#{adapter_name}_policy",
                                   use_same_db: true)
    expect(Casdoor.add_adapter(adapter)).to be(true)

    # Add an enforcer
    enforcer_name = TestUtil.get_random_name('enforceEnforcer')
    enforcer = Casdoor::Enforcer.new(owner: 'casbin', name: enforcer_name, display_name: enforcer_name,
                                     model: "casbin/#{model_name}", adapter: "casbin/#{adapter_name}")
    expect(Casdoor.add_enforcer(enforcer)).to be(true)

    # Add the policies
    expect(Casdoor.add_policy(enforcer, Casdoor::CasbinRule.new(ptype: 'p', v0: 'alice', v1: 'data1', v2: 'read')))
      .to be(true)
    expect(Casdoor.add_policy(enforcer, Casdoor::CasbinRule.new(ptype: 'p', v0: 'bob', v1: 'data2', v2: 'write')))
      .to be(true)

    # Enforce
    req1 = %w[alice data1 read]
    expect(Casdoor.enforce('', '', '', "casbin/#{enforcer_name}", '', req1)).to be(true)

    req2 = %w[bob data2 write]
    expect(Casdoor.enforce('', '', '', "casbin/#{enforcer_name}", '', req2)).to be(true)

    req_fail = %w[alice data1 write]
    expect(Casdoor.enforce('', '', '', "casbin/#{enforcer_name}", '', req_fail)).to be(false)

    # Batch enforce
    res_batch = Casdoor.batch_enforce('', '', '', "casbin/#{enforcer_name}", '', [req1, req_fail])
    expect(res_batch[0][0]).to be(true)
    expect(res_batch[0][1]).to be(false)
  end
end
