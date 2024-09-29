# frozen_string_literal: true

require "rspec/core"
require "factory_bot/syntax/methods"

RSpec.configure do |config|
  config.include FixtureBot::Helpers

  config.before(:suite) do
    FixtureBot.run
  end
end
