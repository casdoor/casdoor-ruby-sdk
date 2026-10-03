# Copyright 2023 The Casdoor Authors. All Rights Reserved.
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
require 'uri'

module CasdoorSdk
  # Converts between the snake_case attributes of the SDK and the camelCase JSON fields of Casdoor
  module JsonFields
    def self.to_snake(key)
      key.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
    end

    def self.to_camel(key)
      head, *tail = key.to_s.split('_')
      ([head] + tail.map { |word| word[0].upcase + word[1..-1] }).join
    end

    def self.dump(value)
      case value
      when Array then value.map { |item| dump(item) }
      when JsonObject then value.to_h
      else value
      end
    end
  end

  # Keeps the fields returned by Casdoor that the SDK doesn't model, so that updating an object doesn't clear them
  module JsonObject
    def to_h
      hash = (@json_fields || {}).transform_keys { |key| JsonFields.to_camel(key) }
      instance_variables.each do |var|
        next if var == :@json_fields

        value = instance_variable_get(var)
        hash[JsonFields.to_camel(var.to_s.delete('@'))] = JsonFields.dump(value) unless value.nil?
      end
      hash
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def json_params(params)
      @json_fields = params
      params.each_with_object({}) { |(key, value), hash| hash[JsonFields.to_snake(key)] = value }
    end
  end

  class ProviderItem
    include JsonObject

    attr_accessor :owner, :name, :can_sign_up, :can_sign_in, :can_unlink, :prompted, :alert_type, :rule, :provider

    def initialize(params)
      params = json_params(params)
      @owner = params[:owner]
      @name = params[:name]
      @can_sign_up = params[:can_sign_up]
      @can_sign_in = params[:can_sign_in]
      @can_unlink = params[:can_unlink]
      @prompted = params[:prompted]
      @alert_type = params[:alert_type]
      @rule = params[:rule]
      @provider = params[:provider]
    end
  end

  class SignupItem
    include JsonObject

    attr_accessor :name, :visible, :required, :prompted, :rule

    def initialize(params)
      params = json_params(params)
      @name = params[:name]
      @visible = params[:visible]
      @required = params[:required]
      @prompted = params[:prompted]
      @rule = params[:rule]
    end
  end

  class Application
    include JsonObject

    attr_accessor :owner, :name, :created_time, :display_name, :logo, :homepage_url, :description, :organization,
                  :cert, :enable_password, :enable_sign_up, :enable_signin_session, :enable_auto_signin,
                  :enable_code_signin, :enable_saml_compress, :enable_web_authn, :enable_link_with_email,
                  :org_choice_mode, :saml_reply_url, :providers, :signup_items, :grant_types, :organization_obj,
                  :tags, :client_id, :client_secret, :redirect_uris, :token_format, :expire_in_hours,
                  :refresh_expire_in_hours, :signup_url, :signin_url, :forget_url, :affiliation_url,
                  :terms_of_use, :signup_html, :signin_html, :theme_data, :form_css, :form_css_mobile,
                  :form_offset, :form_side_html, :form_background_url

    def initialize(params)
      params = json_params(params)
      @owner = params[:owner]
      @name = params[:name]
      @created_time = params[:created_time]
      @display_name = params[:display_name]
      @logo = params[:logo]
      @homepage_url = params[:homepage_url]
      @description = params[:description]
      @organization = params[:organization]
      @cert = params[:cert]
      @enable_password = params[:enable_password]
      @enable_sign_up = params[:enable_sign_up]
      @enable_signin_session = params[:enable_signin_session]
      @enable_auto_signin = params[:enable_auto_signin]
      @enable_code_signin = params[:enable_code_signin]
      @enable_saml_compress = params[:enable_saml_compress]
      @enable_web_authn = params[:enable_web_authn]
      @enable_link_with_email = params[:enable_link_with_email]
      @org_choice_mode = params[:org_choice_mode]
      @saml_reply_url = params[:saml_reply_url]
      @providers = params[:providers].map { |p| ProviderItem.new(p) } if params[:providers]
      @signup_items = params[:signup_items].map { |s| SignupItem.new(s) } if params[:signup_items]
      @grant_types = params[:grant_types]
      @organization_obj = params[:organization_obj]
      @tags = params[:tags]
      @client_id = params[:client_id]
      @client_secret = params[:client_secret]
      @redirect_uris = params[:redirect_uris]
      @token_format = params[:token_format]
      @expire_in_hours = params[:expire_in_hours]
      @refresh_expire_in_hours = params[:refresh_expire_in_hours]
      @signup_url = params[:signup_url]
      @signin_url = params[:signin_url]
      @forget_url = params[:forget_url]
      @affiliation_url = params[:affiliation_url]
      @terms_of_use = params[:terms_of_use]
      @signup_html = params[:signup_html]
      @signin_html = params[:signin_html]
      @theme_data = params[:theme_data]
      @form_css = params[:form_css]
      @form_css_mobile = params[:form_css_mobile]
      @form_offset = params[:form_offset]
      @form_side_html = params[:form_side_html]
      @form_background_url = params[:form_background_url]
    end
  end

  class Client
    attr_accessor :auth_config

    def initialize(auth_config)
      @auth_config = auth_config
    end

    def get_url(action, query_map = {})
      url = "#{@auth_config[:endpoint].chomp('/')}/api/#{action}"
      url += "?#{URI.encode_www_form(query_map)}" unless query_map.empty?
      URI(url)
    end

    def do_get_bytes(url)
      do_request(url, Net::HTTP::Get.new(url))
    end

    def do_post(url, body)
      request = Net::HTTP::Post.new(url, 'Content-Type' => 'application/json')
      request.body = body.to_json
      do_request(url, request)
    end

    def get_applications
      query_map = { "owner" => "admin" }
      url = get_url("get-applications", query_map)

      data = do_get_bytes(url) || []
      data.map { |app_data| Application.new(app_data) }
    end

    def get_organization_applications(owner)
      query_map = { "owner" => "admin", "organization" => owner }
      url = get_url("get-organization-applications", query_map)

      data = do_get_bytes(url) || []
      data.map { |app_data| Application.new(app_data) }
    end

    def get_application(owner, name)
      query_map = { "id" => "#{owner}/#{name}" }
      url = get_url("get-application", query_map)

      data = do_get_bytes(url)
      data && Application.new(data)
    end

    def add_application(application)
      modify_application("add-application", application)
    end

    def delete_application(owner, name)
      # Casdoor only deletes the application when its organization matches too
      application = get_application(owner, name)
      return false if application.nil?

      modify_application("delete-application", application)
    end

    def update_application(application)
      modify_application("update-application", application)
    end

    private

    def modify_application(action, application)
      url = get_url(action, { "id" => "#{application.owner}/#{application.name}" })
      do_post(url, application) == "Affected"
    end

    # Sends the request with the client ID and secret, and returns the data of the Casdoor response
    def do_request(url, request)
      request.basic_auth(@auth_config[:client_id], @auth_config[:client_secret])
      response = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |http|
        http.request(request)
      end

      body = JSON.parse(response.body)
      raise body["msg"] if body["status"] == "error"

      body["data"]
    end
  end
end
