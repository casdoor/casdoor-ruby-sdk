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

require_relative 'casdoor/version'
require_relative 'casdoor/error'
require_relative 'casdoor/entity'
require_relative 'casdoor/auth'
require_relative 'casdoor/util'
require_relative 'casdoor/util_modify'

# The files of the APIs, the same as the casdoorsdk package of the Go SDK
%w[
  adapter application cert email enforce enforcer group invitation jwt ldap logout mfa model notification order
  order_pay organization payment permission plan policy pricing product provider record resource role session sms
  subscription syncer token transaction url user webhook
].each { |file| require_relative "casdoor/#{file}" }

# Must be the last, it delegates all the methods of Client to the module
require_relative 'casdoor/global'
