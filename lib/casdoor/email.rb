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
  # Sending emails with the email provider of the application, the counterpart of email.go of the Go SDK
  class Client
    def send_email(title, content, sender, *receivers)
      form = { 'title' => title, 'content' => content, 'sender' => sender, 'receivers' => receivers.flatten }
      do_post('send-email', nil, form)
      true
    end

    # Sends with the given email provider instead of the application's one
    def send_email_by_provider(title, content, sender, provider, *receivers)
      form = { 'title' => title, 'content' => content, 'sender' => sender, 'receivers' => receivers.flatten }
      do_post('send-email', { 'provider' => provider }, form)
      true
    end
  end
end
