class CreateStatboticsCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :statbotics_caches do |t|
      t.references :frc_team, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true

      # EPA data
      t.float :epa_mean
      t.float :epa_sd

      # Record
      t.integer :wins, default: 0
      t.integer :losses, default: 0
      t.integer :ties, default: 0
      t.integer :qual_wins, default: 0
      t.integer :qual_losses, default: 0
      t.integer :qual_rank
      t.integer :qual_num_teams
      t.float :winrate

      # Full API response for anything else we might need
      t.jsonb :data, default: {}, null: false

      t.datetime :last_synced_at, null: false

      t.timestamps
    end

    add_index :statbotics_caches, [ :event_id, :frc_team_id ], unique: true
    add_index :statbotics_caches, :epa_mean
  end
end
