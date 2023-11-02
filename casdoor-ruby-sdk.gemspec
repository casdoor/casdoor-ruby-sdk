# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'casdoor-ruby-sdk/version'

Gem::Specification.new do |s|
  s.name        = 'casdoor-ruby-sdk'
  s.version     = Casdoor::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Yang Luo']
  s.email       = %w[hsluoyz@qq.com]
  s.homepage    = 'https://github.com/casdoor/casdoor-ruby-sdk'
  s.licenses    = ['Apache License 2.0']
  s.description = 'Ruby SDK for Casdoor'
  s.summary     = 'Ruby SDK for Casdoor'
  s.files = %w[README.md] + Dir.glob(File.join('lib', '**', '*.rb'))
  s.test_files = Dir.glob(File.join('spec', '**', '*.rb'))
  s.required_ruby_version = '>= 2.5.0'

  s.add_dependency 'keisan', '~> 0.8.0'

  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rubocop', '>= 1.8'
  s.add_development_dependency 'rubocop-rspec'
end
