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
  # Setting up the multi-factor authentication of a user, the counterpart of mfa.go of the Go SDK. mfa_type is
  # "app" (TOTP), "sms" or "email". The responses are the hashes of Casdoor, like
  # {"status" => "ok", "msg" => "", "data" => ...}.
  class Client
    # Starts setting up the MFA. For "app", the "data" has the "secret", the "url" of the QR code and the
    # "recoveryCodes".
    def initiate(owner, mfa_type, name)
      do_post('mfa/setup/initiate', nil, { 'owner' => owner, 'mfaType' => mfa_type, 'name' => name }, true)
    end

    # Verifies the passcode of the MFA being set up
    def verify(owner, mfa_type, name, secret, passcode)
      form = { 'owner' => owner, 'mfaType' => mfa_type, 'name' => name, 'secret' => secret, 'passcode' => passcode }
      do_post('mfa/setup/verify', nil, form, true)
    end

    # Enables the MFA after it's verified
    def enable(owner, mfa_type, name, secret, recovery_code)
      form = { 'owner' => owner, 'mfaType' => mfa_type, 'name' => name, 'secret' => secret,
               'recoveryCodes' => recovery_code }
      do_post('mfa/setup/enable', nil, form.reject { |_, value| value.to_s.empty? }, true)
    end

    def set_preferred(owner, mfa_type, name, secret)
      form = { 'owner' => owner, 'mfaType' => mfa_type, 'name' => name, 'secret' => secret }
      do_post('set-preferred-mfa', nil, form.reject { |_, value| value.to_s.empty? }, true)
      true
    end

    # Disables all the MFA of the user
    def delete(owner, name)
      do_post('delete-mfa', { 'owner' => owner, 'name' => name }, nil)
      true
    end
  end
end
