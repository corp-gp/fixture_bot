# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter(/schema\.rb/)
end

ENV["RAILS_ENV"] = "test"
ENV["BUNDLE_GEMFILE"] = "#{File.dirname(__FILE__)}/../Gemfile"

require "bundler/setup"

require "rails"
require "active_record/railtie"

module RSpec
  class Application < ::Rails::Application
    config.root = "#{File.dirname(__FILE__)}/support/app"
    config.active_support.deprecation = :log
    config.eager_load = false
  end
end

ActiveRecord::Migration.verbose = true
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
# RSpec::Application.initialize!

load "#{File.dirname(__FILE__)}/support/app/db/schema.rb"

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

require "fixture_bot"

FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end