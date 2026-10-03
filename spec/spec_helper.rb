# frozen_string_literal: true

require 'casdoor'
require 'webmock/rspec'

# The unit tests stub the HTTP requests, while the integration tests call the Casdoor of CASDOOR_TEST_ENDPOINT
WebMock.disable_net_connect!(allow_localhost: true, allow: ENV.fetch('CASDOOR_TEST_ENDPOINT', nil))

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  config.filter_run_excluding(:integration) unless ENV['CASDOOR_TEST_ENDPOINT']
end
