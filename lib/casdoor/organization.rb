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
  class Organization < Entity; end

  # The organization APIs, the counterpart of organization.go of the Go SDK
  class Client
    def get_organization(name)
      get_object('get-organization', Organization, 'id' => get_admin_id(name))
    end

    def get_organizations
      get_objects('get-organizations', Organization, 'owner' => 'admin')
    end

    # The organizations with only their names and display names
    def get_organization_names
      get_objects('get-organization-names', Organization, 'owner' => 'admin')
    end

    def add_organization(organization)
      modify_object('add-organization', Organization, organization, 'admin')
    end

    def delete_organization(organization)
      modify_object('delete-organization', Organization, organization, 'admin')
    end

    def update_organization(organization)
      modify_object('update-organization', Organization, organization, 'admin')
    end
  end
end
