# frozen_string_literal: true

class CreatePitScoutingEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :pit_scouting_entries do |t|
      t.references :organization, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.references :frc_team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :data, default: {}, null: false
      t.text :notes
      t.integer :status, default: 0, null: false
      t.string :client_uuid

      t.timestamps
    end

    add_index :pit_scouting_entries, :client_uuid, unique: true
    add_index :pit_scouting_entries, :data, using: :gin
    add_index :pit_scouting_entries, [ :event_id, :frc_team_id, :user_id ],
              unique: true, name: "idx_pit_scouting_entries_unique"
  end
end
