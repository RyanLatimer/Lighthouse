# frozen_string_literal: true

class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.integer :team_number
      t.string :slug, null: false
      t.jsonb :settings, default: {}, null: false

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
    add_index :organizations, :team_number
  end
end
