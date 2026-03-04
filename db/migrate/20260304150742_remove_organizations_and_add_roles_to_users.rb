class RemoveOrganizationsAndAddRolesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :integer, default: 0, null: false

    # Remove organization_id from all tables that reference it
    remove_reference :data_conflicts, :organization, foreign_key: true
    remove_reference :events, :organization, foreign_key: true
    remove_reference :game_configs, :organization, foreign_key: true
    remove_reference :pick_lists, :organization, foreign_key: true
    remove_reference :pit_scouting_entries, :organization, foreign_key: true
    remove_reference :predictions, :organization, foreign_key: true
    remove_reference :reports, :organization, foreign_key: true
    remove_reference :scouting_entries, :organization, foreign_key: true
    remove_reference :simulation_results, :organization, foreign_key: true

    # Drop join tables and roles
    drop_table :memberships
    drop_table :users_roles
    drop_table :roles

    # Drop organizations
    drop_table :organizations
  end
end
