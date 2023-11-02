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

require 'test/unit'
require_relative './test_util'
require_relative '../lib/application'

module CasdoorSdk
  class TestCasdoorSDK < Test::Unit::TestCase
    def setup
      auth_config = {
        endpoint: TestCasdoorEndpoint,
        client_id: TestClientId,
        client_secret: TestClientSecret,
        certificate: TestJwtPublicKey,
        organization_name: TestCasdoorOrganization,
        application_name: TestCasdoorApplication,
      }
      $casdoor_client = Client.new(auth_config)
    end

    def test_application
      name = get_random_name("application")

      # Add a new object
      application = Application.new({
                                      owner: "admin",
                                      name: name,
                                      created_time: get_current_time,
                                      display_name: name,
                                      logo: "https://cdn.casbin.org/img/casdoor-logo_1185x256.png",
                                      homepage_url: "https://casdoor.org",
                                      description: "Casdoor Website",
                                      organization: "casbin"
                                    })

      begin
        $casdoor_client.add_application(application)
      rescue => e
        fail("Failed to add object: #{e}")
      end

      # Get all objects, check if our added object is inside the list
      begin
        applications = $casdoor_client.get_applications
      rescue => e
        fail("Failed to get objects: #{e}")
      end

      found = applications.any? { |item| item.name == name }
      fail("Added object not found in list") unless found

      # Get the object
      begin
        retrieved_application = $casdoor_client.get_application("admin", name)
      rescue => e
        fail("Failed to get object: #{e}")
      end

      assert_equal(name, retrieved_application.name, "Retrieved object does not match added object")

      # Update the object
      updated_description = "Updated Casdoor Website"
      retrieved_application.description = updated_description

      begin
        $casdoor_client.update_application(retrieved_application)
      rescue => e
        fail("Failed to update object: #{e}")
      end

      # Validate the update
      begin
        updated_application = $casdoor_client.get_application("admin", name)
      rescue => e
        fail("Failed to get updated object: #{e}")
      end

      assert_equal(updated_description, updated_application.description, "Failed to update object, description mismatch")

      # Delete the object
      begin
        $casdoor_client.delete_application("admin", name)
      rescue => e
        fail("Failed to delete object: #{e}")
      end

      # Validate the deletion
      begin
        deleted_application = $casdoor_client.get_application("admin", name)
        fail("Failed to delete object, it's still retrievable") if deleted_application
      rescue => e
        # Expected error, object should not be found
      end
    end

    def get_random_name(prefix)
      # Implement a function to generate a random name with the given prefix
      "#{prefix}_#{rand(10000)}"
    end

    def get_current_time
      # Implement a function to get the current time in the required format
      Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
    end
  end
end
