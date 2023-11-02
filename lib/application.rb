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
  class ProviderItem
    attr_accessor :owner, :name, :can_sign_up, :can_sign_in, :can_unlink, :prompted, :alert_type, :rule, :provider

    def initialize(params)
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
    attr_accessor :name, :visible, :required, :prompted, :rule

    def initialize(params)
      @name = params[:name]
      @visible = params[:visible]
      @required = params[:required]
      @prompted = params[:prompted]
      @rule = params[:rule]
    end
  end

  class Application
    attr_accessor :owner, :name, :created_time, :display_name, :logo, :homepage_url, :description, :organization,
                  :cert, :enable_password, :enable_sign_up, :enable_signin_session, :enable_auto_signin,
                  :enable_code_signin, :enable_saml_compress, :enable_web_authn, :enable_link_with_email,
                  :org_choice_mode, :saml_reply_url, :providers, :signup_items, :grant_types, :organization_obj,
                  :tags, :client_id, :client_secret, :redirect_uris, :token_format, :expire_in_hours,
                  :refresh_expire_in_hours, :signup_url, :signin_url, :forget_url, :affiliation_url,
                  :terms_of_use, :signup_html, :signin_html, :theme_data, :form_css, :form_css_mobile,
                  :form_offset, :form_side_html, :form_background_url

    def initialize(params)
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

    def get_url(action, query_map)
      URI::HTTP.build({
                        host: @auth_config[:endpoint],
                        path: "/api/#{action}",
                        query: URI.encode_www_form(query_map)
                      })
    end

    def do_get_bytes(url)
      Net::HTTP.get(url)
    end

    def get_applications
      query_map = { "owner" => "admin" }
      url = get_url("get-applications", query_map)

      response = do_get_bytes(url)
      data = JSON.parse(response, symbolize_names: true)

      data.map { |app_data| Application.new(app_data) }
    end

    def get_organization_applications(owner)
      query_map = { "owner" => owner }
      url = get_url("get-organization-applications", query_map)

      response = do_get_bytes(url)
      data = JSON.parse(response, symbolize_names: true)

      data.map { |app_data| Application.new(app_data) }
    end

    def get_application(owner, name)
      query_map = { "owner" => owner, "name" => name }
      url = get_url("get-application", query_map)

      response = do_get_bytes(url)
      data = JSON.parse(response, symbolize_names: true)

      Application.new(data)
    end

    def add_application(application)
      url = get_url("add-application", {})
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = application.to_json
      response = http.request(request)
      JSON.parse(response.body, symbolize_names: true)
    end

    def delete_application(owner, name)
      query_map = { "owner" => owner, "name" => name }
      url = get_url("delete-application", query_map)

      response = do_get_bytes(url)
      JSON.parse(response, symbolize_names: true)
    end

    def update_application(application)
      url = get_url("update-application", {})
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Put.new(uri.path, 'Content-Type' => 'application/json')
      request.body = application.to_json
      response = http.request(request)
      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
