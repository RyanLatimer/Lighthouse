# frozen_string_literal: true

class CreatePredictions < ActiveRecord::Migration[8.1]
  def change
    create_table :predictions do |t|
      t.references :match, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :organization, foreign_key: true
      t.float :red_score
      t.float :blue_score
      t.float :red_win_probability
      t.float :blue_win_probability
      t.jsonb :details, default: {}, null: false
      t.string :source # "scouting", "statbotics", "blended"
      t.integer :actual_red_score
      t.integer :actual_blue_score

      t.timestamps
    end

    add_index :predictions, [ :match_id, :organization_id, :source ],
              unique: true, name: "idx_predictions_unique"
  end
end
