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

module Casdoor
  # A policy of an enforcer, e.g. CasbinRule.new(ptype: "p", v0: "alice", v1: "data1", v2: "read"). Casdoor names
  # its JSON fields "Ptype", "V0", ..., "V5".
  class CasbinRule < Entity
    def self.field_key(name)
      name.to_s.capitalize
    end
  end

  # A filter of get_filtered_policies, e.g. PolicyFilter.new(ptype: "g", field_index: 0, field_values: ["alice"])
  class PolicyFilter < Entity; end

  # The policy APIs of the enforcers, the counterpart of policy.go of the Go SDK
  class Client
    def add_policy(enforcer, policy)
      modify_policy('add-policy', enforcer, [policy])
    end

    def update_policy(enforcer, old_policy, new_policy)
      modify_policy('update-policy', enforcer, [old_policy, new_policy])
    end

    def remove_policy(enforcer, policy)
      modify_policy('remove-policy', enforcer, [policy])
    end

    # adapter_id ("owner/name") can be empty to use the adapter of the enforcer
    def get_policies(enforcer_name, adapter_id)
      get_objects('get-policies', CasbinRule, 'id' => get_id(enforcer_name), 'adapterId' => adapter_id)
    end

    # The policies of the enforcer ("owner/name") that match all the filters
    def get_filtered_policies(enforcer_id, filters)
      filters = filters.map { |filter| to_entity(PolicyFilter, filter) }
      (do_post('get-filtered-policies', { 'id' => enforcer_id }, filters)['data'] || []).map do |item|
        CasbinRule.new(item)
      end
    end

    private

    def modify_policy(action, enforcer, policies)
      enforcer = to_entity(Enforcer, enforcer)
      enforcer.owner = organization_name if enforcer.owner.to_s.empty?
      policies = policies.map { |policy| to_entity(CasbinRule, policy) }

      body = action == 'update-policy' ? policies : policies.first
      do_post(action, { 'id' => enforcer.get_id }, body)['data'] == 'Affected'
    end
  end
end
