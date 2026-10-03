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
  # Base class of all the errors raised by the SDK
  class Error < StandardError; end

  # Casdoor answered the request with an error, e.g. {"status": "error", "msg": "..."} or an OAuth error
  class ApiError < Error; end

  # Casdoor answered with an unexpected HTTP status or a body that isn't JSON
  class HttpError < Error
    attr_reader :status, :body

    def initialize(status, body)
      @status = status
      @body = body
      super("Casdoor returned HTTP #{status}: #{body.to_s[0, 500]}")
    end
  end

  # The JWT token can't be verified with the certificate, or it has expired, or it's issued to another application
  class InvalidTokenError < Error; end
end
