# frozen_string_literal: true

require "factory_bot"
require "active_record"

module FixtureBot
  require "fixture_bot/helpers"
  require "fixture_bot/fixture_creator"
  require "fixture_bot/table_loader"
  require "fixture_bot/version"
  require "fixture_bot/rspec" if defined?(RSpec)
  require "fixture_bot/minitest" if defined?(Minitest)
  require "fixture_bot/extension"

  module_function

  def after_load_fixtures(&block)
    @after_load_fixtures = block
  end

  def run
    cached_mtime, cached_record_ids = cached_fixtures
    if cached_mtime && cached_mtime == max_mtime_fixtures.iso8601(6)
      colored_output "Cache load fixtures"

      FixtureBot::FixtureCreator.record_ids = Marshal.load(Base64.decode64(cached_record_ids))
      define_fixture_helpers
    else
      colored_output "Full load fixtures"

      ActiveRecord::Tasks::DatabaseTasks.truncate_all
      load_models
      define_fixture_helpers
      FixtureBot::FixtureCreator.load_to_db
      @after_load_fixtures&.call
      caching_max_mtime_fixtures(Marshal.dump(FixtureBot::FixtureCreator.record_ids))
    end
  end

  def max_mtime_fixtures
    @max_mtime_fixtures ||=
      FactoryBot.definition_file_paths.flat_map { |path|
        directory_path = File.expand_path(path)

        if File.directory?(directory_path)
          Dir[File.join(directory_path, "**", "*.rb")].map { |file| File.mtime(file) }
        end
      }.compact.max.round(6)
  end

  # One statement per call: adapters such as SQLite run only the first statement of a batch.
  # Columns are text so that every adapter reads back what it wrote: the time is compared as
  # an ISO 8601 string, and the dump is Base64. v1 used timestamptz and bytea
  def cached_fixtures
    connection.execute("CREATE TABLE IF NOT EXISTS __fixture_bot_cache_v2(fixtures_time text, fixtures_dump text)")
    connection.select_rows("SELECT fixtures_time, fixtures_dump FROM __fixture_bot_cache_v2").first
  end

  # The table keeps exactly one row: truncate_all clears it only where database configs are known
  def caching_max_mtime_fixtures(dump_record_ids)
    connection.execute("DELETE FROM __fixture_bot_cache_v2")
    connection.execute <<~SQL
      INSERT INTO __fixture_bot_cache_v2
      VALUES (#{connection.quote(max_mtime_fixtures.iso8601(6))}, #{connection.quote(Base64.encode64(dump_record_ids))})
    SQL
  end

  def load_models
    return unless defined?(Rails)

    Dir[Rails.application.root.join("app/models/**/*.rb")].each do |file|
      require_dependency file
    end
  end

  def define_fixture_helpers
    ::FactoryBot::SyntaxRunner.include(::FixtureBot::Helpers)
  end

  def connection
    ::ActiveRecord::Base.connection
  end

  def colored_output(text)
    puts "\e[33m#{text}\e[0m"
  end
end
