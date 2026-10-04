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
  # The permission checks, the counterpart of enforce.go of the Go SDK. One of permission_id, model_id, resource_id,
  # enforcer_id ("owner/name") or owner chooses the policies to check, the others are empty strings.
  class Client
    # casbin_request is a Casbin request like ["alice", "data1", "read"]. Returns true if any of the checked
    # permissions allows it.
    def enforce(permission_id, model_id, resource_id, enforcer_id, owner, casbin_request)
      data = do_enforce('enforce', permission_id, model_id, resource_id, enforcer_id, owner, casbin_request)
      raise ApiError, 'invalid data' unless data.is_a?(Array)

      data.any?(true)
    end

    # casbin_requests is a list of Casbin requests. Returns the results of each checked permission, like
    # [[true, false]] for two requests checked against one permission.
    def batch_enforce(permission_id, model_id, resource_id, enforcer_id, owner, casbin_requests)
      data = do_enforce('batch-enforce', permission_id, model_id, resource_id, enforcer_id, owner, casbin_requests)
      raise ApiError, 'invalid data' unless data.is_a?(Array) && data.all?(Array)

      data
    end

    private

    def do_enforce(action, permission_id, model_id, resource_id, enforcer_id, owner, body)
      query = { 'permissionId' => permission_id, 'modelId' => model_id, 'resourceId' => resource_id,
                'enforcerId' => enforcer_id, 'owner' => owner }
      do_post(action, query, body)['data']
    end
  end
end
