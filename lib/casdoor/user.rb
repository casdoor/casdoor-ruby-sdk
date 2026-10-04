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
  class User < Entity; end

  # The user APIs, the counterpart of user.go of the Go SDK
  class Client
    # The users of all the organizations, only allowed for global admins
    def get_global_users
      get_objects('get-global-users', User, nil)
    end

    def get_users
      get_objects('get-users', User, 'owner' => organization_name)
    end

    # sorter is the DB column to sort by, e.g. "created_time"
    def get_sorted_users(sorter, limit)
      get_objects('get-sorted-users', User, 'owner' => organization_name, 'sorter' => sorter, 'limit' => limit.to_s)
    end

    # Returns the users of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_users(page, page_size, query_map = {})
      get_pagination_objects('get-users', User, organization_name, page, page_size, query_map)
    end

    # is_online is "" to count all the users, "1" or true for the online ones, "0" or false for the offline ones
    def get_user_count(is_online = '')
      is_online = { true => '1', false => '0', nil => '' }.fetch(is_online, is_online)
      do_get_bytes(get_url('get-user-count', 'owner' => organization_name, 'isOnline' => is_online)).to_i
    end

    def get_user(name)
      get_object('get-user', User, 'id' => get_id(name))
    end

    # The user that the client is authenticated as. It's meant to be used with a client returned by
    # with_access_token, so that the user of an access token can be retrieved:
    #
    #   user = client.with_access_token(token["access_token"]).get_account
    def get_account
      get_object('get-account', User, nil)
    end

    def get_user_by_email(email)
      get_object('get-user', User, 'owner' => organization_name, 'email' => email)
    end

    def get_user_by_phone(phone)
      get_object('get-user', User, 'owner' => organization_name, 'phone' => phone)
    end

    # user_id is the "id" field of the user (a UUID), not "owner/name"
    def get_user_by_user_id(user_id)
      get_object('get-user', User, 'owner' => organization_name, 'userId' => user_id)
    end

    # old_password isn't required when an admin sets the password of another user, pass an empty string then
    def set_password(owner, name, old_password, new_password)
      form = { 'userOwner' => owner, 'userName' => name, 'oldPassword' => old_password, 'newPassword' => new_password }
      do_post('set-password', nil, form, true)['status'] == 'ok'
    end

    # Updates the user of the ID ("owner/name"), e.g. to rename the user
    def update_user_by_id(id, user)
      modify_user_by_id('update-user', id, user)
    end

    # Updates the user of the user ID (the "id" field of the user)
    def update_user_by_user_id(owner, user_id, user)
      user = to_entity(User, user)
      do_post('update-user', { 'owner' => owner, 'userId' => user_id }, user)['data'] == 'Affected'
    end

    def update_user(user)
      modify_object('update-user', User, user, organization_name)
    end

    def update_user_for_columns(user, columns)
      modify_object('update-user', User, user, organization_name, columns)
    end

    def add_user(user)
      modify_object('add-user', User, user, organization_name)
    end

    def delete_user(user)
      modify_object('delete-user', User, user, organization_name)
    end

    # Checks the password of a user, e.g. User.new(owner: "casbin", name: "alice", password: "123").
    # Returns false when the password is wrong.
    def check_user_password(user)
      user = to_entity(User, user)
      user.owner = organization_name if user.owner.to_s.empty?
      do_post('check-user-password', { 'id' => user.get_id }, user)['status'] == 'ok'
    rescue ApiError
      false
    end

    private

    def modify_user_by_id(action, id, user)
      user = to_entity(User, user)
      user.owner = organization_name if user.owner.to_s.empty?
      do_post(action, { 'id' => id }, user)['data'] == 'Affected'
    end
  end
end
