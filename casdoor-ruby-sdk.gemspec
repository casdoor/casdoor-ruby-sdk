# frozen_string_literal: true

require_relative 'lib/casdoor/version'

Gem::Specification.new do |s|
  s.name        = 'casdoor-ruby-sdk'
  s.version     = Casdoor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Yang Luo']
  s.email       = %w[hsluoyz@qq.com]
  s.homepage    = 'https://github.com/casdoor/casdoor-ruby-sdk'
  s.licenses    = ['Apache-2.0']
  s.summary     = 'Ruby SDK for Casdoor'
  s.description = 'Ruby SDK for Casdoor: sign users in with OAuth 2.0 / OIDC, verify the JWT tokens, and manage ' \
                  'users, organizations, applications, roles, permissions and the other objects of Casdoor.'
  s.files = %w[README.md LICENSE] + Dir.glob(File.join('lib', '**', '*.rb'))
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 2.7.0'
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_dependency 'jwt', '>= 2.5', '< 4'
end
