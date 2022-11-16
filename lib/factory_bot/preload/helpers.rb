# frozen_string_literal: true

module FactoryBot
  module Preload
    module Helpers
      def self.included(_base)
        ::FactoryBot::Preload::FixtureCreator.tables.each_key do |table|
          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            # def users(name)
            #   fixture_get(name, User, :users)
            # end
            def #{table}(name)
              fixture_get(name, :#{table})
            end
          RUBY
        end
      end

      private def fixture_get(name, table)
        if (global_id = Preload::FixtureCreator.record_ids.dig(table, name) ||
           Preload::FixtureCreator.force_load_fixture(table, name))
          GlobalID::Locator.locate global_id
        else
          raise "Couldn't find #{name.inspect} fixture for Global Id #{global_id}"
        end
      end
    end
  end
end

