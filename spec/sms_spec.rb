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

RSpec.describe 'Casdoor SMS API', :integration do
  # The CI data has no SMS provider, like the Go SDK, so only the request is checked: Casdoor answers that the
  # application has no SMS provider
  it 'sends an SMS' do
    TestUtil.init_config

    expect { Casdoor.send_sms('casdoor-ruby-sdk test', '+15555550100') }
      .to raise_error(Casdoor::ApiError, /provider/i)
  end
end
