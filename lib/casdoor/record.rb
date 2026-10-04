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
  class Record < Entity; end

  # The record APIs, the counterpart of record.go of the Go SDK
  class Client
    def get_records
      get_objects('get-records', Record, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_records(page, page_size, query_map = {})
      get_pagination_objects('get-records', Record, organization_name, page, page_size, query_map)
    end

    # Gets the record by name, or nil if it doesn't exist. Casdoor has no API to get a single record, so it searches
    # the records by name. Like the other APIs that read records, it needs the access token of an admin user, see
    # with_access_token().
    def get_record(name)
      name = name.to_s.split('/').last.to_s
      # The name filter matches the records whose names contain the given name
      records, = get_pagination_records(1, 100, 'field' => 'name', 'value' => name)
      records.find { |record| record.name == name }
    end

    def add_record(record)
      record = to_entity(Record, record)
      record.owner = organization_name if record.owner.to_s.empty?
      record.organization = organization_name if record.organization.to_s.empty?
      do_post('add-record', nil, record)['data'] == 'Affected'
    end
  end
end
