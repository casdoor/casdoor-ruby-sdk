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
  # The counterpart of the *_global.go files of the Go SDK: every public method of Client can also be called on the
  # module, with the global client initialized by Casdoor.init_config:
  #
  #   Casdoor.init_config(endpoint, client_id, client_secret, certificate, organization_name, application_name)
  #   users = Casdoor.get_users
  def self.global_client
    @global_client or raise Error, 'The global client is not initialized, call Casdoor.init_config first'
  end

  (Client.public_instance_methods(false) - %i[endpoint client_id client_secret certificate organization_name
                                              application_name access_token custom_headers custom_headers=
                                              open_timeout open_timeout= read_timeout read_timeout=]).each do |method|
    define_singleton_method(method) do |*args, **kwargs, &block|
      global_client.public_send(method, *args, **kwargs, &block)
    end
  end
end
