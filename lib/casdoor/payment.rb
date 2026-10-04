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
  class Payment < Entity; end

  # The payment APIs, the counterpart of payment.go of the Go SDK
  class Client
    def get_payments
      get_objects('get-payments', Payment, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_payments(page, page_size, query_map = {})
      get_pagination_objects('get-payments', Payment, organization_name, page, page_size, query_map)
    end

    def get_payment(name)
      get_object('get-payment', Payment, 'id' => get_id(name))
    end

    def get_user_payments(user_name)
      get_objects('get-user-payments', Payment,
                  'owner' => organization_name, 'organization' => organization_name, 'user' => user_name)
    end

    def update_payment(payment)
      modify_object('update-payment', Payment, payment, organization_name)
    end

    def add_payment(payment)
      modify_object('add-payment', Payment, payment, organization_name)
    end

    def delete_payment(payment)
      modify_object('delete-payment', Payment, payment, organization_name)
    end

    def notify_payment(payment)
      modify_object('notify-payment', Payment, payment, organization_name)
    end

    def invoice_payment(payment)
      modify_object('invoice-payment', Payment, payment, organization_name)
    end
  end
end
