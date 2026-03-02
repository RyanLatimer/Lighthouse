# frozen_string_literal: true

class CreateSimulationResults < ActiveRecord::Migration[8.1]
  def change
    create_table :simulation_results do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :organization, foreign_key: true
      t.string :name
      t.jsonb :red_team_ids, default: [], null: false
      t.jsonb :blue_team_ids, default: [], null: false
      t.jsonb :results, default: {}, null: false
      t.integer :iterations, default: 1000

      t.timestamps
    end
  end
end
