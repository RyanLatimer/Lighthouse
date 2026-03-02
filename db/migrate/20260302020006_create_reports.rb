# frozen_string_literal: true

class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :name, null: false
      t.jsonb :config, default: {}, null: false
      t.jsonb :cached_data, default: {}
      t.datetime :last_generated_at

      t.timestamps
    end
  end
end
