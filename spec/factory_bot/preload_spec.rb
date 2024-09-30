# frozen_string_literal: true

require "spec_helper"

describe FixtureBot do
  it "injects model methods" do
    expect { users(:john) }.not_to raise_error
  end

  it "returns :john factory for User model" do
    expect(users(:john)).to be_an(User)
  end

  it "returns :ruby factory for Skill model" do
    expect(skills(:ruby)).to be_a(Skill)
  end

  it "returns :my factory for Preload model" do
    expect(preloads(:my)).to be_a(Preload)
  end

  it "reuses existing factories" do
    expect(skills(:ruby).user).to eq(users(:john))
  end

  it "raises error for missing factories" do
    expect { users(:mary) }.to raise_error("Couldn't find fixture users/mary")
  end

  it "ignores reserved table names when creating helpers" do
    mod =
      Module.new do
        include FixtureBot::Helpers
      end

    instance = Object.new.extend(mod)

    expect(instance).not_to respond_to(:active_record_internal_metadata)
    expect(instance).not_to respond_to(:active_record_schema_migrations)
    expect(instance).not_to respond_to(:primary_schema_migrations)
  end

  example "association uses preloaded record" do
    expect(build(:skill).user).to eq(users(:john))
  end

  context "fixture with id" do
    it "super admin user" do
      expect(users(:ivan)).to be_super_admin
      expect(users(:john)).not_to be_super_admin
    end
  end

  context "reloadable factories" do
    it "freezes object" do
      user = users(:john)
      user.destroy
      expect(user).to be_frozen
    end

    it "updates invitation count" do
      user = users(:john)

      user.increment(:invitations)
      user.save

      expect(user.invitations).to eq(1)
    end

    it "reloads factory" do
      expect(users(:john).invitations).to eq(0)
      expect(users(:john)).not_to be_frozen
    end
  end
end
