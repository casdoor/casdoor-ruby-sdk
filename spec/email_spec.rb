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

RSpec.describe 'Casdoor email API', :integration do
  it 'sends an email' do
    TestUtil.init_config

    # The SMTP server of the CI data doesn't exist, so only the errors of sending the email itself are allowed
    begin
      expect(Casdoor.send_email('casbin', 'casdoor-ruby-sdk website test', 'admin', 'TestSmtpServer')).to be(true)
    rescue Casdoor::ApiError => e
      expect(e.message).to match(%r{535 Error|i/o timeout|connection refused|no such host|dial tcp}i)
    end
  end
end
