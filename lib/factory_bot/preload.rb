# frozen_string_literal: true

require "factory_bot"
require "active_record"

module FactoryBot
  module Preload

    require "factory_bot/preload/helpers"
    require "factory_bot/preload/fixture_creator"
    require "factory_bot/preload/table_loader"
    require "factory_bot/preload/version"
    require "factory_bot/preload/rspec" if defined?(RSpec)
    require "factory_bot/preload/minitest" if defined?(Minitest)
    require "factory_bot/preload/extension"

    module_function

    def after_load_fixtures(&block)
      @after_load_fixtures = block
    end

    def run
      cached_mtime, cached_record_ids = cached_fixtures
      if cached_mtime && cached_mtime == max_mtime_fixtures
        puts "Cache load fixtures".yellow

        FactoryBot::Preload::FixtureCreator.record_ids = Marshal.load(cached_record_ids)
        define_fixture_helpers
      else
        puts "Full load fixtures".yellow

        clean_db
        load_models
        define_fixture_helpers
        FactoryBot::Preload::FixtureCreator.load_to_db
        @after_load_fixtures&.call
        caching_max_mtime_fixtures(Marshal.dump(FactoryBot::Preload::FixtureCreator.record_ids))
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
        CREATE TABLE IF NOT EXISTS __factory_bot_preload_cache_v1(fixtures_time timestamptz, fixtures_dump bytea);
        SELECT fixtures_time, fixtures_dump FROM __factory_bot_preload_cache_v1
      SQL
    end

    def caching_max_mtime_fixtures(dump_record_ids)
      connection.execute <<-SQL
        TRUNCATE TABLE __factory_bot_preload_cache_v1;
        INSERT INTO __factory_bot_preload_cache_v1 VALUES ('#{max_mtime_fixtures.iso8601(6)}', '#{connection.raw_connection.escape_bytea(dump_record_ids)}')
      SQL
    end

    def load_models
      return unless defined?(Rails)

      Dir[Rails.application.root.join("app/models/**/*.rb")].each do |file|
        require_dependency file
      end
    end

    def define_fixture_helpers
      ::FactoryBot::SyntaxRunner.include(::FactoryBot::Preload::Helpers)
    end

    RESERVED_TABLES = %w[
      ar_internal_metadata
      schema_migrations
    ].freeze

    def clean_db
      tables = connection.tables - RESERVED_TABLES

      query =
        case connection.adapter_name
        when "SQLite"
          tables.map { |table| "DELETE FROM #{connection.quote_table_name(table)}" }.join(";")
        when "PostgreSQL"
          "TRUNCATE TABLE #{tables.map { |table| connection.quote_table_name(table) }.join(',')} RESTART IDENTITY CASCADE"
        else
          "TRUNCATE TABLE #{tables.map { |table| connection.quote_table_name(table) }.join(',')}"
        end

      connection.disable_referential_integrity do
        connection.execute(query)
      end
    end

    def connection
      ::ActiveRecord::Base.connection
    end
  end
end
