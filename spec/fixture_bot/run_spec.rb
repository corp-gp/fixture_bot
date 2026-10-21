# frozen_string_literal: true

require "spec_helper"

describe FixtureBot, ".run" do
  # The suite has already loaded fixtures in before(:suite); an example that reloads them
  # must hand the original record ids back, or later examples look up rolled-back records
  around(:each) do |example|
    record_ids = FixtureBot::FixtureCreator.record_ids
    example.run
  ensure
    FixtureBot::FixtureCreator.record_ids = record_ids
  end

  it "loads fixtures from cache when factory files are unchanged" do
    john_id = users(:john).id

    expect { described_class.run }.to output(/Cache load fixtures/).to_stdout
    expect(users(:john).id).to eq(john_id)
  end

  it "reloads fixtures when factory files have changed" do
    allow(described_class).to receive(:max_mtime_fixtures).and_return(Time.now.round(6) + 60)

    expect { described_class.run }.to output(/Full load fixtures/).to_stdout
    expect { described_class.run }.to output(/Cache load fixtures/).to_stdout
  end
end
