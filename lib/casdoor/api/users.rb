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
    # The user APIs besides the ones in Crud
    module Users
      # The user that the client is authenticated as, meant to be used with with_access_token:
      #
      #   user = client.with_access_token(access_token).get_account
      def get_account
        data = get_data('get-account')
        data && User.new(data)
      end

      # The users of all the organizations, only allowed for global admins
      def get_global_users
        (get_data('get-global-users') || []).map { |item| User.new(item) }
      end

      def get_sorted_users(sorter, limit)
        query = { 'owner' => organization_name, 'sorter' => sorter, 'limit' => limit }
        (get_data('get-sorted-users', query) || []).map { |item| User.new(item) }
      end

      # is_online: nil counts all the users, true or false counts the online or offline ones
      def get_user_count(is_online: nil)
        online = { nil => '', true => '1', false => '0' }.fetch(is_online)
        query = { 'owner' => organization_name, 'isOnline' => online }
        get_data('get-user-count', query).to_i
      end

      def get_user_by_email(email)
        find_user('email' => email)
      end

      def get_user_by_phone(phone)
        find_user('phone' => phone)
      end

      # user_id is the "id" field of the user (a UUID), not "owner/name"
      def get_user_by_user_id(user_id)
        find_user('userId' => user_id)
      end

      # Sets the user's password. old_password can be empty when an admin sets the password of another user.
      def set_password(owner, name, new_password, old_password: '')
        form = { 'userOwner' => owner, 'userName' => name, 'oldPassword' => old_password,
                 'newPassword' => new_password }
        post_form('set-password', {}, form)['status'] == 'ok'
      end

      # Checks the password of a user, e.g. User.new(owner: "casbin", name: "alice", password: "123")
      def check_user_password(user)
        user = User.new(user) if user.is_a?(Hash)
        user.owner = organization_name if user.owner.to_s.empty?
        post_json('check-user-password', { 'id' => "#{user.owner}/#{user.name}" }, user)['status'] == 'ok'
      rescue ApiError
        false
      end

      private

      def find_user(query)
        data = get_data('get-user', { 'owner' => organization_name }.merge(query))
        data && User.new(data)
      end
    end
  end
end
