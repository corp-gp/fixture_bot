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

case ENV.fetch("FIXTURE_BOT_DB", "sqlite")
when "sqlite"
  ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
when "postgresql"
  ActiveRecord::Base.establish_connection(
    adapter:  "postgresql",
    host:     ENV.fetch("FIXTURE_BOT_PG_HOST", "localhost"),
    port:     ENV.fetch("FIXTURE_BOT_PG_PORT", 5432),
    username: ENV.fetch("FIXTURE_BOT_PG_USER", "postgres"),
    password: ENV.fetch("FIXTURE_BOT_PG_PASSWORD", nil),
    database: ENV.fetch("FIXTURE_BOT_PG_DATABASE", "test_fixture_bot"),
  )
  # Unlike :memory: SQLite, the database outlives the run: a fixture cache left by the previous
  # run would point at records that schema.rb has just dropped
  ActiveRecord::Base.connection.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public")
else
  raise "FIXTURE_BOT_DB must be sqlite or postgresql, got #{ENV.fetch('FIXTURE_BOT_DB').inspect}"
end
# RSpec::Application.initialize!

load "#{File.dirname(__FILE__)}/support/app/db/schema.rb"

require "rspec/rails"

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end

require "fixture_bot"

module AfterLoadFixturesCalls
  def self.list = @list ||= []
end
FixtureBot.after_load_fixtures { AfterLoadFixturesCalls.list << :first }
FixtureBot.after_load_fixtures { AfterLoadFixturesCalls.list << :second }

FactoryBot.find_definitions

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
