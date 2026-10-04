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
  # An LDAP server of an organization. Unlike the other objects, it's identified by "owner/id" instead of
  # "owner/name".
  class Ldap < Entity
    def get_id
      "#{self[:owner]}/#{self[:id]}"
    end
  end

  class LdapUser < Entity; end

  # The LDAP APIs, the counterpart of ldap.go of the Go SDK
  class Client
    def get_ldaps
      get_objects('get-ldaps', Ldap, 'owner' => 'admin')
    end

    def get_ldap(id)
      get_object('get-ldap', Ldap, 'id' => get_admin_id(id))
    end

    def add_ldap(ldap)
      modify_object('add-ldap', Ldap, ldap, 'admin')
    end

    def delete_ldap(ldap)
      modify_object('delete-ldap', Ldap, ldap, 'admin')
    end

    def update_ldap(ldap)
      modify_object('update-ldap', Ldap, ldap, 'admin')
    end

    # The users in the LDAP server. Returns a hash like {"users" => [LdapUser], "existUuids" => [...]}.
    def get_ldap_users(id)
      data = do_get_bytes(get_url('get-ldap-users', 'id' => get_id(id))) || {}
      data.merge('users' => (data['users'] || []).map { |user| LdapUser.new(user) })
    end

    # Imports the LDAP users into Casdoor. Returns a hash like {"exist" => [LdapUser], "failed" => [LdapUser]}.
    def sync_ldap_users(id, users)
      data = do_post('sync-ldap-users', { 'id' => get_id(id) }, users.map { |user| to_entity(LdapUser, user) })['data']
      (data || {}).to_h { |key, value| [key, (value || []).map { |user| LdapUser.new(user) }] }
    end

    # Imports all the users of the LDAP server into Casdoor
    def sync_ldap_users_from_server(id)
      sync_ldap_users(id, get_ldap_users(id)['users'])
    end
  end
end
