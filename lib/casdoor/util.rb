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
require 'net/http'
require 'securerandom'
require 'time'
require 'uri'

module Casdoor
  # The current time in RFC 3339, the format of the "createdTime" of Casdoor
  def self.get_current_time
    Time.now.iso8601
  end

  # The HTTP layer, the counterpart of util.go of the Go SDK. Any Casdoor API can be called with these methods,
  # authenticated as the client. The responses of Casdoor are hashes like
  # {"status" => "ok", "msg" => "", "data" => ..., "data2" => ...}.
  class Client
    def get_url(action, query_map = nil)
      query = (query_map || {}).compact.transform_keys(&:to_s)
      url = "#{endpoint}/api/#{action}"
      query.empty? ? url : "#{url}?#{URI.encode_www_form(query)}"
    end

    # "owner/name" with the client's organization as the owner, unless name is already "owner/name"
    def get_id(name)
      get_owner_id(name, organization_name)
    end

    # Calls a GET API, and returns the whole response
    def do_get_response(url)
      body = parse_body(perform(Net::HTTP::Get.new(URI(url))))
      raise ApiError, body['msg'].to_s unless body.is_a?(Hash) && body['status'] == 'ok'

      body
    end

    # Calls a GET API, and returns the "data" of the response
    def do_get_bytes(url)
      do_get_response(url)['data']
    end

    # Calls a GET API, and returns the raw body of the response
    def do_get_bytes_raw(url)
      response = perform(Net::HTTP::Get.new(URI(url)))
      check_response(parse_body(response)) if response['Content-Type'].to_s.include?('json')
      response.body
    end

    # Calls a POST API, and returns the whole response. The body is posted as JSON, or as form fields when is_form,
    # or as a file named "file" when is_file.
    def do_post(action, query_map, post_body, is_form = false, is_file = false)
      request = Net::HTTP::Post.new(URI(get_url(action, query_map)))
      if is_file
        request.set_form([['file', post_body.to_s, { filename: 'file' }]], 'multipart/form-data')
      elsif is_form
        request.set_form((post_body || {}).to_h.transform_keys(&:to_s).transform_values(&:to_s), 'multipart/form-data')
      else
        request['Content-Type'] = 'application/json'
        request.body = post_body.nil? || post_body.is_a?(String) ? post_body.to_s : post_body.to_json
      end

      body = parse_body(perform(request))
      raise ApiError, body['msg'].to_s unless body.is_a?(Hash) && body['status'] == 'ok'

      body
    end

    # Calls a POST API, and returns the raw body of the response
    def do_post_bytes_raw(url, content_type, body)
      request = Net::HTTP::Post.new(URI(url))
      request['Content-Type'] = content_type.to_s.empty? ? 'text/plain;charset=UTF-8' : content_type
      request.body = body
      perform(request).body
    end

    private

    def get_owner_id(name, default_owner)
      name.to_s.include?('/') ? name.to_s : "#{default_owner}/#{name}"
    end

    def get_admin_id(name)
      get_owner_id(name, 'admin')
    end

    def set_auth_header(request)
      if access_token
        request['Authorization'] = "Bearer #{access_token}"
      else
        request.basic_auth(client_id.to_s, client_secret.to_s)
      end
    end

    def perform(request, auth: true)
      set_auth_header(request) if auth
      request['Accept'] ||= 'application/json'
      custom_headers.each { |key, value| request[key] = value }

      uri = request.uri
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: open_timeout,
                                          read_timeout: read_timeout) do |http|
        http.request(request)
      end
    end

    # Parses the JSON body. Errors of the HTTP layer are raised, while the {"status": "error"} responses are left to
    # the caller.
    def parse_body(response)
      begin
        body = JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        raise HttpError.new(response.code.to_i, response.body)
      end

      return body if response.is_a?(Net::HTTPSuccess)
      # Casdoor answers some errors with a non-2xx status and a JSON body that explains the error
      return body if body.is_a?(Hash) && (body['status'] == 'error' || body['error'])

      raise HttpError.new(response.code.to_i, response.body)
    end

    def send_request(request, auth: true)
      parse_body(perform(request, auth: auth))
    end

    def check_response(body)
      raise ApiError, body['msg'].to_s if body.is_a?(Hash) && body['status'] == 'error'

      body
    end
  end
end
