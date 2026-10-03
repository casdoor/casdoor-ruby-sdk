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
    # The add/get/update/delete APIs that all the Casdoor objects share. For each object, e.g. the user, it defines:
    #
    #   get_users(**query)                         # => [User]
    #   get_pagination_users(page, page_size, **query) # => [[User], total count]
    #   get_user(name)                             # => User or nil, name can be "name" or "owner/name"
    #   add_user(user)                             # => true if added
    #   update_user(user, columns: nil)            # => true if changed, columns limits the updated fields
    #   delete_user(user_or_name)                  # => true if deleted
    #
    # The objects belong to the client's organization, except the ones in ADMIN_OWNED, which belong to "admin".
    # A different owner can be passed with "owner/name", the owner field of the object, or owner: in the query.
    # Extra query parameters of the list APIs can be passed in snake_case, e.g. get_users(sort_field: "name").
    module Crud
      OBJECTS = {
        adapter: Adapter,
        application: Application,
        cert: Cert,
        enforcer: Enforcer,
        group: Group,
        invitation: Invitation,
        model: Model,
        order: Order,
        organization: Organization,
        payment: Payment,
        permission: Permission,
        plan: Plan,
        pricing: Pricing,
        product: Product,
        provider: Provider,
        resource: Resource,
        role: Role,
        subscription: Subscription,
        syncer: Syncer,
        token: Token,
        transaction: Transaction,
        user: User,
        webhook: Webhook
      }.freeze

      ADMIN_OWNED = %i[application organization token].freeze

      OBJECTS.each do |object, klass|
        plural = "#{object}s"

        define_method("get_#{plural}") do |**query|
          data = get_data("get-#{plural}", list_query(object, query)) || []
          data.map { |item| klass.new(item) }
        end

        define_method("get_pagination_#{plural}") do |page, page_size, **query|
          query = list_query(object, query).merge('p' => page, 'pageSize' => page_size)
          response = get_response("get-#{plural}", query)
          [(response['data'] || []).map { |item| klass.new(item) }, response['data2'].to_i]
        end

        define_method("get_#{object}") do |name|
          data = get_data("get-#{object}", 'id' => object_id_of(object, name))
          data && klass.new(data)
        end

        define_method("add_#{object}") do |entity|
          modify_object("add-#{object}", object, entity)
        end

        define_method("update_#{object}") do |entity, columns: nil|
          modify_object("update-#{object}", object, entity, columns: columns)
        end

        # Casdoor deletes an object by the whole object, e.g. an application is only deleted when its organization
        # matches too, so the object is fetched first when only its name is given
        define_method("delete_#{object}") do |entity|
          entity = send("get_#{object}", entity) unless entity.is_a?(Entity)
          return false if entity.nil?

          modify_object("delete-#{object}", object, entity)
        end
      end

      private

      def default_owner(object)
        ADMIN_OWNED.include?(object) ? 'admin' : organization_name
      end

      def object_id_of(object, name)
        name.to_s.include?('/') ? name.to_s : "#{default_owner(object)}/#{name}"
      end

      def list_query(object, query)
        query = query.each_with_object({}) { |(key, value), hash| hash[Entity.camelize(key)] = value }
        { 'owner' => default_owner(object) }.merge(query)
      end

      def modify_object(action, object, entity, columns: nil, query: {})
        entity = OBJECTS.fetch(object).new(entity) if entity.is_a?(Hash)
        entity.owner = default_owner(object) if entity.owner.to_s.empty?

        query = { 'id' => "#{entity.owner}/#{entity.name}" }.merge(query)
        query['columns'] = Array(columns).map { |column| Entity.camelize(column) }.join(',') if columns
        post_json(action, query, entity)['data'] == 'Affected'
      end
    end
  end
end
