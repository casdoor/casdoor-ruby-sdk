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

require 'json'

module Casdoor
  # An object of Casdoor, like a user or an application. It keeps all the JSON fields returned by Casdoor, so that
  # updating an object never clears the fields that the SDK doesn't know about, and the fields added by newer
  # Casdoor versions work without updating the SDK.
  #
  # The fields can be read and written in snake_case, which is converted to the camelCase name used by Casdoor:
  #
  #   user.display_name             # => user["displayName"]
  #   user.email = "alice@example.com"
  #   user.is_admin?                # => true or false
  #   user[:display_name]           # Symbol keys are converted too
  #   user["displayName"]           # String keys are used as is
  #
  # The fields whose names are taken by Ruby's own methods (e.g. "hash" of a user, "method" of a provider) can
  # only be accessed with [], like user["hash"].
  #
  # Nested objects (e.g. application.providers) are plain hashes with the camelCase keys of Casdoor.
  class Entity
    def self.camelize(key)
      key.to_s.gsub(/_([a-z\d])/) { Regexp.last_match(1).upcase }
    end

    def initialize(attributes = {})
      @attributes = {}
      (attributes || {}).each { |key, value| self[key] = value }
    end

    def [](key)
      @attributes[field_name(key)]
    end

    def []=(key, value)
      @attributes[field_name(key)] = value
    end

    def key?(key)
      @attributes.key?(field_name(key))
    end

    def to_h
      @attributes.dup
    end

    def to_json(*args)
      @attributes.to_json(*args)
    end

    def ==(other)
      other.class == self.class && other.to_h == to_h
    end

    def inspect
      "#<#{self.class.name} #{@attributes.inspect}>"
    end

    def method_missing(method_name, *args)
      field = method_name.to_s
      if field.end_with?('=') && args.length == 1
        self[Entity.camelize(field.chomp('='))] = args.first
      elsif field.end_with?('?') && args.empty?
        self[Entity.camelize(field.chomp('?'))] ? true : false
      elsif args.empty? && field.match?(/\A[a-z][a-z\d_]*\z/)
        self[Entity.camelize(field)]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.match?(/\A[a-z][a-z\d_]*[=?]?\z/) || super
    end

    private

    # String keys are the exact names of Casdoor, while Symbol keys are snake_case
    def field_name(key)
      key.is_a?(Symbol) ? Entity.camelize(key) : key.to_s
    end
  end

  class Adapter < Entity; end
  class Application < Entity; end
  class Cert < Entity; end
  class Enforcer < Entity; end
  class Group < Entity; end
  class Invitation < Entity; end
  class Model < Entity; end
  class Order < Entity; end
  class Organization < Entity; end
  class Payment < Entity; end
  class Permission < Entity; end
  class Plan < Entity; end
  class Pricing < Entity; end
  class Product < Entity; end
  class Provider < Entity; end
  class Resource < Entity; end
  class Role < Entity; end
  class Session < Entity; end
  class Subscription < Entity; end
  class Syncer < Entity; end
  class Token < Entity; end
  class Transaction < Entity; end
  class User < Entity; end
  class Webhook < Entity; end

  # The claims of a JWT token issued by Casdoor: the fields of the user, plus the standard claims like "exp" and "aud"
  class Claims < Entity
    def user
      User.new(to_h)
    end

    # Casdoor names the claim "tokenType", or "TokenType" for the "JWT-Custom" token format
    def refresh_token?
      (self['tokenType'] || self['TokenType']) == 'refresh-token'
    end
  end
end
