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
    if cached_mtime && cached_mtime == max_mtime_fixtures
      colored_output "Cache load fixtures"

      FixtureBot::FixtureCreator.record_ids = Marshal.load(Base64.decode64(cached_record_ids))
      define_fixture_helpers
    else
      colored_output "Full load fixtures"

      clean_db
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

  def cached_fixtures
    connection.query(<<-SQL).first
      CREATE TABLE IF NOT EXISTS __fixture_bot_cache_v1(fixtures_time timestamptz, fixtures_dump bytea);
      SELECT fixtures_time, fixtures_dump FROM __fixture_bot_cache_v1
    SQL
  end

  def caching_max_mtime_fixtures(dump_record_ids)
    truncate_tables(["__fixture_bot_cache_v1"])
    connection.execute <<-SQL
      INSERT INTO __fixture_bot_cache_v1 VALUES ('#{max_mtime_fixtures.iso8601(6)}', '#{Base64.encode64(dump_record_ids)}')
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

  RESERVED_TABLES = %w[
    ar_internal_metadata
    schema_migrations
  ].freeze

  def clean_db
    connection.disable_referential_integrity do
      connection.execute(truncate_tables(connection.tables - RESERVED_TABLES))
    end
  end

  def connection
    ::ActiveRecord::Base.connection
  end

  def truncate_tables(tables)
    case connection.adapter_name
    when "SQLite"
      tables.map { |table| "DELETE FROM #{connection.quote_table_name(table)}" }.join(";")
    when "PostgreSQL"
      "TRUNCATE TABLE #{tables.map { |table| connection.quote_table_name(table) }.join(',')} RESTART IDENTITY CASCADE"
    else
      "TRUNCATE TABLE #{tables.map { |table| connection.quote_table_name(table) }.join(',')}"
    end
  end

  def colored_output(text)
    puts "\e[33m#{text}\e[0m"
  end
end
