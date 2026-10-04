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
  # The helpers shared by the APIs of the objects, the counterpart of util_modify.go of the Go SDK
  class Client
    private

    def get_objects(action, klass, query_map)
      (do_get_bytes(get_url(action, query_map)) || []).map { |item| klass.new(item) }
    end

    # Returns the objects of the page and the total count
    def get_pagination_objects(action, klass, owner, page, page_size, query_map)
      query = to_query_map(query_map).merge('owner' => owner, 'p' => page.to_s, 'pageSize' => page_size.to_s)
      response = do_get_response(get_url(action, query))
      [(response['data'] || []).map { |item| klass.new(item) }, response['data2'].to_i]
    end

    def get_object(action, klass, query_map)
      data = do_get_bytes(get_url(action, query_map))
      data && klass.new(data)
    end

    # Posts the object to an add/update/delete API, and returns whether the object is affected. The owner of the
    # object defaults to default_owner, and columns limits the updated fields. Most APIs answer "Affected" or
    # "Unaffected", while some (e.g. update-model) answer only "ok" when they succeed.
    def modify_object(action, klass, object, default_owner, columns = nil, query_map = {})
      object = to_entity(klass, object)
      object.owner = default_owner if object.owner.to_s.empty?

      query = { 'id' => object.get_id }.merge(query_map)
      if columns && !columns.empty?
        query['columns'] = columns.map do |column|
          column.is_a?(Symbol) ? Entity.camelize(column) : column
        end.join(',')
      end
      do_post(action, query, object)['data'] != 'Unaffected'
    end

    def to_entity(klass, object)
      object.is_a?(Entity) ? object : klass.new(object)
    end

    # Symbol keys are snake_case, e.g. sort_field: "name", while String keys are the names of Casdoor
    def to_query_map(query_map)
      (query_map || {}).each_with_object({}) do |(key, value), query|
        query[key.is_a?(Symbol) ? Entity.camelize(key) : key.to_s] = value
      end
    end
  end
end
