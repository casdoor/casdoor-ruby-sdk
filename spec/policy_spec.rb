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

RSpec.describe 'Casdoor policy API', :integration do
  def new_enforcer(name)
    Casdoor::Enforcer.new(
      owner: TestUtil::TEST_CASDOOR_ORGANIZATION,
      name: name,
      created_time: Casdoor.get_current_time,
      display_name: name,
      model: 'built-in/user-model-built-in',
      adapter: 'built-in/user-adapter-built-in',
      description: 'Casdoor Website'
    )
  end

  it 'adds, updates and removes a policy' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Enforcer')

    # Add a new enforcer
    enforcer = new_enforcer(name)
    expect(Casdoor.add_enforcer(enforcer)).to be(true)

    # Add a policy
    # The enforcers of the built-in adapter share the policies, so the policy may already exist
    policy = Casdoor::CasbinRule.new(ptype: 'p', v0: '1', v1: '2', v2: '4')
    Casdoor.add_policy(enforcer, policy)

    # Get all policies, check if our added policy is inside the list
    policies = Casdoor.get_policies(name, '')
    expect(policies.any? { |item| item.ptype == 'p' && item.v2 == '4' }).to be(true)

    # Update the policy
    new_policy = Casdoor::CasbinRule.new(ptype: 'p', v0: '1', v1: '2', v2: '5')
    expect(Casdoor.update_policy(enforcer, policy, new_policy)).to be(true)

    # Validate the update
    policies = Casdoor.get_policies(name, '')
    expect(policies.any? { |item| item.ptype == 'p' && item.v2 == '5' }).to be(true)

    # Remove the policy
    expect(Casdoor.remove_policy(enforcer, new_policy)).to be(true)

    # Validate the removal
    policies = Casdoor.get_policies(name, '')
    expect(policies.any? { |item| item.ptype == 'p' && item.v2 == '5' }).to be(false)

    expect(Casdoor.delete_enforcer(enforcer)).to be(true)
  end

  it 'gets the filtered policies' do
    TestUtil.init_config

    name = TestUtil.get_random_name('Enforcer')

    # Add a new enforcer
    enforcer = new_enforcer(name)
    expect(Casdoor.add_enforcer(enforcer)).to be(true)

    # Add the policies
    Casdoor.add_policy(enforcer, Casdoor::CasbinRule.new(ptype: 'g', v0: 'built-in/Test1', v1: 'group:built-in/Test1'))
    Casdoor.add_policy(enforcer, Casdoor::CasbinRule.new(ptype: 'g', v0: 'built-in/Test2', v1: 'group:built-in/Test2'))
    Casdoor.add_policy(enforcer, Casdoor::CasbinRule.new(ptype: 'p', v0: '1', v1: '2', v2: '4'))

    enforcer_id = "#{TestUtil::TEST_CASDOOR_ORGANIZATION}/#{name}"

    # Filter by one value of a field
    filters = [Casdoor::PolicyFilter.new(ptype: 'g', field_index: 0, field_values: ['built-in/Test1'])]
    policies = Casdoor.get_filtered_policies(enforcer_id, filters)
    expect(policies.any? { |policy| policy.ptype == 'g' && policy.v0 == 'built-in/Test1' }).to be(true)

    # Filter by several values of a field
    filters = [Casdoor::PolicyFilter.new(ptype: 'g', field_index: 0, field_values: %w[built-in/Test1 built-in/Test2])]
    policies = Casdoor.get_filtered_policies(enforcer_id, filters)
    expect(policies.size).to be >= 2

    # Filter by another field
    filters = [Casdoor::PolicyFilter.new(ptype: 'g', field_index: 1, field_values: ['group:built-in/Test1'])]
    policies = Casdoor.get_filtered_policies(enforcer_id, filters)
    expect(policies.any? { |policy| policy.ptype == 'g' && policy.v1 == 'group:built-in/Test1' }).to be(true)

    # Filter by the policy type only
    filters = [Casdoor::PolicyFilter.new(ptype: 'g')]
    policies = Casdoor.get_filtered_policies(enforcer_id, filters)
    expect(policies.size).to be >= 2

    # Filter by several fields
    filters = [
      Casdoor::PolicyFilter.new(ptype: 'p', field_index: 0, field_values: ['1']),
      Casdoor::PolicyFilter.new(ptype: 'p', field_index: 1, field_values: ['2'])
    ]
    policies = Casdoor.get_filtered_policies(enforcer_id, filters)
    expect(policies.any? { |policy| policy.ptype == 'p' && policy.v0 == '1' && policy.v1 == '2' }).to be(true)

    expect(Casdoor.delete_enforcer(enforcer)).to be(true)
  end
end
