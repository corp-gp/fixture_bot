# frozen_string_literal: true

ActiveRecord::Schema.define(version: 0) do
  create_table :users, force: true do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.integer :invitations, null: false, default: 0
  end

  add_index :users, :email, unique: true

  create_table :preloads, force: true do |t|
    t.string :name
  end

  create_table :skills, force: true do |t|
    t.references :user
  end

  create_table :categories, force: true

  create_table :categories_users, id: false, force: true do |t|
    t.references :category
    t.references :user
  end

  create_table :assets, force: true do |t|
    t.string :name
  end
end
