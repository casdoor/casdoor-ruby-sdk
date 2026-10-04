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
  class Resource < Entity; end

  # The resource (uploaded file) APIs, the counterpart of resource.go of the Go SDK
  class Client
    # id is "owner/name", where the name of a resource is its path, like "/casdoor/avatar/casbin/alice.png"
    def get_resource(id)
      get_object('get-resource', Resource, 'owner' => organization_name, 'id' => id)
    end

    def get_resource_ex(owner, name)
      get_resource("#{owner}/#{name}")
    end

    def get_resources(owner, user, field, value, sort_field, sort_order)
      get_objects('get-resources', Resource, 'owner' => owner, 'user' => user, 'field' => field, 'value' => value,
                                             'sortField' => sort_field, 'sortOrder' => sort_order)
    end

    def get_pagination_resources(owner, user, field, value, page_size, page, sort_field, sort_order)
      get_objects('get-resources', Resource, 'owner' => owner, 'user' => user, 'field' => field, 'value' => value,
                                             'p' => page.to_s, 'pageSize' => page_size.to_s,
                                             'sortField' => sort_field, 'sortOrder' => sort_order)
    end

    # Uploads a file for the user with the storage provider of the client's application.
    # Returns [the URL of the file, the name of the resource].
    def upload_resource(user, tag, parent, full_file_path, file_bytes)
      upload_resource_ex(user, tag, parent, full_file_path, file_bytes, nil, nil)
    end

    def upload_resource_ex(user, tag, parent, full_file_path, file_bytes, created_time, description)
      query = { 'owner' => organization_name, 'user' => user, 'application' => application_name, 'tag' => tag,
                'parent' => parent, 'fullFilePath' => full_file_path, 'createdTime' => created_time,
                'description' => description }
      response = do_post('upload-resource', query, file_bytes, true, true)
      [response['data'], response['data2']]
    end

    def add_resource(resource)
      modify_object('add-resource', Resource, resource, organization_name)
    end

    def update_resource(resource)
      modify_object('update-resource', Resource, resource, organization_name)
    end

    def delete_resource(resource)
      delete_resource_with_tag(resource, '')
    end

    # A tag of "avatar" etc. also deletes the file from the storage
    def delete_resource_with_tag(resource, tag)
      resource = to_entity(Resource, resource)
      resource.owner = organization_name if resource.owner.to_s.empty?
      do_post('delete-resource', { 'tag' => tag }, resource)['data'] == 'Affected'
    end
  end
end
