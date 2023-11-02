# Copyright 2023 The Casdoor Authors. All Rights Reserved.
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

module CasdoorSdk
  class AuthConfig
    attr_accessor :endpoint, :client_id, :client_secret, :certificate, :organization_name, :application_name

    def initialize(endpoint, client_id, client_secret, certificate, organization_name, application_name)
      @endpoint = endpoint
      @client_id = client_id
      @client_secret = client_secret
      @certificate = certificate
      @organization_name = organization_name
      @application_name = application_name
    end
  end

  class Client
    attr_accessor :auth_config

    def initialize(auth_config)
      @auth_config = auth_config
    end
  end

  @global_client = nil

  def self.init_config(endpoint, client_id, client_secret, certificate, organization_name, application_name)
    @global_client = new_client(endpoint, client_id, client_secret, certificate, organization_name, application_name)
  end

  def self.new_client(endpoint, client_id, client_secret, certificate, organization_name, application_name)
    new_client_with_conf(
      AuthConfig.new(endpoint, client_id, client_secret, certificate, organization_name, application_name)
    )
  end

  def self.new_client_with_conf(config)
    Client.new(config)
  end
end
