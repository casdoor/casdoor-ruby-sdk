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
  module Api
    # The permission checks of Casdoor. Pass one of permission_id, model_id, resource_id, enforcer_id or owner
    # ("owner/name" for the IDs) to choose which policies to check against.
    module Enforce
      # request is a Casbin request like ["alice", "data1", "read"]. Returns true if any of the checked
      # permissions allows it.
      def enforce(request, permission_id: nil, model_id: nil, resource_id: nil, enforcer_id: nil, owner: nil)
        query = enforce_query(permission_id, model_id, resource_id, enforcer_id, owner)
        Array(post_json('enforce', query, request)['data']).any?(true)
      end

      # requests is a list of Casbin requests. Returns a list of results for each checked permission, like
      # [[true, false]] for two requests checked against one permission.
      def batch_enforce(requests, permission_id: nil, model_id: nil, resource_id: nil, enforcer_id: nil, owner: nil)
        query = enforce_query(permission_id, model_id, resource_id, enforcer_id, owner)
        post_json('batch-enforce', query, requests)['data'] || []
      end

      private

      def enforce_query(permission_id, model_id, resource_id, enforcer_id, owner)
        { 'permissionId' => permission_id, 'modelId' => model_id, 'resourceId' => resource_id,
          'enforcerId' => enforcer_id, 'owner' => owner }
      end
    end
  end
end
