# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter(/schema\.rb/)
end

ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = "#{File.dirname(__FILE__)}/../Gemfile"

require "bundler/setup"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

require "minitest/utils"

class SampleApplication < Rails::Application
  config.api = true
  config.root = "#{__dir__}/../spec/support/app"
  config.active_support.deprecation = :log
  config.eager_load = false
end

SampleApplication.initialize!
require "rails/test_help"

ActiveRecord::Migration.verbose = true
ActiveRecord::Base.establish_connection("sqlite3::memory:")
load "#{__dir__}/../spec/support/app/db/schema.rb"

module ActiveSupport
  class TestCase
    self.use_instantiated_fixtures = true
  end
end

require "fixture_bot"
require "#{__dir__}/../spec/support/factories"

FixtureBot.minitest
