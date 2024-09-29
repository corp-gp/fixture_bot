# frozen_string_literal: true

require "minitest"
require "factory_bot/syntax/methods"

module FixtureBot
  module Preload
    def self.minitest
      ::FixtureBot.clean
      ::FixtureBot.run
    end

    module MinitestSetup
      def setup
        ::FixtureBot.reload_factories
        super
      end
    end

    ::Minitest::Test.include Helpers
    ::Minitest::Test.prepend MinitestSetup
  end
end
