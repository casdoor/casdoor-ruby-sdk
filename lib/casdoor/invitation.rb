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
  class Invitation < Entity; end

  # The invitation APIs, the counterpart of invitation.go of the Go SDK
  class Client
    def get_invitations
      get_objects('get-invitations', Invitation, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_invitations(page, page_size, query_map = {})
      get_pagination_objects('get-invitations', Invitation, organization_name, page, page_size, query_map)
    end

    def get_invitation(name)
      get_object('get-invitation', Invitation, 'id' => get_id(name))
    end

    # The invitation of the code, for the application (in "admin") that the user signs up with
    def get_invitation_info(code, application_name)
      get_object('get-invitation-info', Invitation, 'applicationId' => "admin/#{application_name}", 'code' => code)
    end

    def update_invitation(invitation)
      modify_object('update-invitation', Invitation, invitation, organization_name)
    end

    def update_invitation_for_columns(invitation, columns)
      modify_object('update-invitation', Invitation, invitation, organization_name, columns)
    end

    def add_invitation(invitation)
      modify_object('add-invitation', Invitation, invitation, organization_name)
    end

    def delete_invitation(invitation)
      modify_object('delete-invitation', Invitation, invitation, organization_name)
    end
  end
end
