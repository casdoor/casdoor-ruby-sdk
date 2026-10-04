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
  class Cert < Entity; end

  # The cert APIs, the counterpart of cert.go of the Go SDK
  class Client
    # The certs of all the organizations, only allowed for global admins
    def get_global_certs
      get_objects('get-global-certs', Cert, nil)
    end

    def get_certs
      get_objects('get-certs', Cert, 'owner' => organization_name)
    end

    def get_cert(name)
      get_object('get-cert', Cert, 'id' => get_id(name))
    end

    def add_cert(cert)
      modify_object('add-cert', Cert, cert, organization_name)
    end

    def update_cert(cert)
      modify_object('update-cert', Cert, cert, organization_name)
    end

    def delete_cert(cert)
      modify_object('delete-cert', Cert, cert, organization_name)
    end
  end
end
