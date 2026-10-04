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
  class Transaction < Entity; end

  # The transaction APIs, the counterpart of transaction.go of the Go SDK
  class Client
    def get_transactions
      get_objects('get-transactions', Transaction, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_transactions(page, page_size, query_map = {})
      get_pagination_objects('get-transactions', Transaction, organization_name, page, page_size, query_map)
    end

    def get_transaction(name)
      get_object('get-transaction', Transaction, 'id' => get_id(name))
    end

    # Casdoor has no get-user-transactions API, get-transactions filters the transactions by user
    def get_user_transactions(user_name)
      get_objects('get-transactions', Transaction, 'owner' => organization_name, 'field' => 'user',
                                                   'value' => user_name)
    end

    def update_transaction(transaction)
      modify_object('update-transaction', Transaction, transaction, organization_name)
    end

    # Returns [true, the ID (name) of the new transaction]
    def add_transaction(transaction)
      add_transaction_with_dry_run(transaction, false)
    end

    # With dry_run, Casdoor only validates the transaction without saving it
    def add_transaction_with_dry_run(transaction, dry_run)
      transaction = to_entity(Transaction, transaction)
      transaction.owner = organization_name if transaction.owner.to_s.empty?
      query = { 'id' => transaction.get_id }
      query['dryRun'] = '1' if dry_run
      [true, do_post('add-transaction', query, transaction)['data'].to_s]
    end

    def delete_transaction(transaction)
      modify_object('delete-transaction', Transaction, transaction, organization_name)
    end
  end
end
