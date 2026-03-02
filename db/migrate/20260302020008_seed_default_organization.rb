# frozen_string_literal: true

class SeedDefaultOrganization < ActiveRecord::Migration[8.1]
  def up
    # Create a default organization for existing data
    org_id = execute(<<~SQL).first&.dig("id")
      INSERT INTO organizations (name, team_number, slug, settings, created_at, updated_at)
      VALUES ('Default Team', 1234, 'default-team', '{}', NOW(), NOW())
      RETURNING id
    SQL

    return unless org_id

    # Assign all existing data to the default organization
    execute("UPDATE events SET organization_id = #{org_id} WHERE organization_id IS NULL")
    execute("UPDATE scouting_entries SET organization_id = #{org_id} WHERE organization_id IS NULL")
    execute("UPDATE pick_lists SET organization_id = #{org_id} WHERE organization_id IS NULL")
    execute("UPDATE data_conflicts SET organization_id = #{org_id} WHERE organization_id IS NULL")
    execute("UPDATE game_configs SET organization_id = #{org_id} WHERE organization_id IS NULL")

    # Create memberships for all existing users with owner role
    execute(<<~SQL)
      INSERT INTO memberships (user_id, organization_id, role, created_at, updated_at)
      SELECT id, #{org_id}, 4, NOW(), NOW() FROM users
      ON CONFLICT (user_id, organization_id) DO NOTHING
    SQL
  end

  def down
    execute("DELETE FROM memberships")
    execute("DELETE FROM organizations")
    execute("UPDATE events SET organization_id = NULL")
    execute("UPDATE scouting_entries SET organization_id = NULL")
    execute("UPDATE pick_lists SET organization_id = NULL")
    execute("UPDATE data_conflicts SET organization_id = NULL")
    execute("UPDATE game_configs SET organization_id = NULL")
  end
end
