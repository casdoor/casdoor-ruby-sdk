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
  class Application < Entity; end

  # The application APIs, the counterpart of application.go of the Go SDK
  class Client
    def get_applications
      get_objects('get-applications', Application, 'owner' => 'admin')
    end

    # The applications of the client's organization
    def get_organization_applications
      get_objects('get-organization-applications', Application,
                  'owner' => 'admin', 'organization' => organization_name)
    end

    def get_application(name)
      get_object('get-application', Application, 'id' => get_admin_id(name))
    end

    def add_application(application)
      modify_object('add-application', Application, application, 'admin')
    end

    def delete_application(application)
      modify_object('delete-application', Application, application, 'admin')
    end

    def update_application(application)
      modify_object('update-application', Application, application, 'admin')
    end
  end
end
