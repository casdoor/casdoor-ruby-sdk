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
  class Webhook < Entity; end

  # The webhook APIs, the counterpart of webhook.go of the Go SDK
  class Client
    def get_webhooks
      get_objects('get-webhooks', Webhook, 'owner' => organization_name)
    end

    # Returns the objects of the page and the total count. query_map can filter and sort them, e.g.
    # { field: "name", value: "alice", sort_field: "created_time", sort_order: "descend" }
    def get_pagination_webhooks(page, page_size, query_map = {})
      get_pagination_objects('get-webhooks', Webhook, organization_name, page, page_size, query_map)
    end

    def get_webhook(name)
      get_object('get-webhook', Webhook, 'id' => get_id(name))
    end

    def update_webhook(webhook)
      modify_object('update-webhook', Webhook, webhook, organization_name)
    end

    def add_webhook(webhook)
      modify_object('add-webhook', Webhook, webhook, organization_name)
    end

    def delete_webhook(webhook)
      modify_object('delete-webhook', Webhook, webhook, organization_name)
    end
  end
end
