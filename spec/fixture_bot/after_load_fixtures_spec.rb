# frozen_string_literal: true

require "spec_helper"

describe FixtureBot, ".after_load_fixtures" do
  it "runs every added block in order after loading fixtures" do
    expect(AfterLoadFixturesCalls.list).to eq(%i[first second])
  end
end
