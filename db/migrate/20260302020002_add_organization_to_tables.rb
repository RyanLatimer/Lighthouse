# frozen_string_literal: true

class AddOrganizationToTables < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :organization, foreign_key: true
    add_reference :scouting_entries, :organization, foreign_key: true
    add_reference :pick_lists, :organization, foreign_key: true
    add_reference :data_conflicts, :organization, foreign_key: true
    add_reference :game_configs, :organization, foreign_key: true
  end
end
