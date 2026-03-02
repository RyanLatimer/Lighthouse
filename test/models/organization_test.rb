require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid organization from fixtures" do
    assert organizations(:team_254).valid?
    assert organizations(:team_1678).valid?
  end

  test "requires name" do
    org = Organization.new(slug: "test-org")
    assert_not org.valid?
    assert_includes org.errors[:name], "can't be blank"
  end

  test "requires slug" do
    org = Organization.new(name: "Test Org")
    # slug is auto-generated on create, but if we bypass callback:
    org.slug = nil
    org.validate
    # When creating, slug gets generated; test explicit blank after save attempt
    org_saved = organizations(:team_254)
    org_saved.slug = nil
    assert_not org_saved.valid?
    assert_includes org_saved.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    org = Organization.new(name: "Duplicate", slug: "team-254")
    assert_not org.valid?
    assert_includes org.errors[:slug], "has already been taken"
  end

  test "slug format allows lowercase letters numbers and hyphens" do
    org = Organization.new(name: "Test", slug: "valid-slug-123")
    org.valid?
    assert_empty org.errors[:slug].select { |e| e.include?("only allows") }
  end

  test "slug format rejects uppercase" do
    org = Organization.new(name: "Test", slug: "Invalid-Slug")
    assert_not org.valid?
    assert org.errors[:slug].any? { |e| e.include?("only allows") }
  end

  test "slug format rejects spaces" do
    org = Organization.new(name: "Test", slug: "invalid slug")
    assert_not org.valid?
    assert org.errors[:slug].any? { |e| e.include?("only allows") }
  end

  test "slug format rejects special characters" do
    org = Organization.new(name: "Test", slug: "invalid_slug!")
    assert_not org.valid?
    assert org.errors[:slug].any? { |e| e.include?("only allows") }
  end

  # --- Callbacks ---

  test "generates slug from name on create" do
    org = Organization.create!(name: "My Cool Team")
    assert_equal "my-cool-team", org.slug
  end

  test "generates unique slug when duplicate exists" do
    Organization.create!(name: "Team 254 Clone", slug: "team-254-clone")
    org2 = Organization.create!(name: "Team 254 Clone")
    assert_equal "team-254-clone-1", org2.slug
  end

  test "does not overwrite existing slug on create" do
    org = Organization.create!(name: "Custom Name", slug: "custom-slug")
    assert_equal "custom-slug", org.slug
  end

  # --- Associations ---

  test "has many memberships" do
    org = organizations(:team_254)
    assert_respond_to org, :memberships
    assert_includes org.memberships, memberships(:admin_membership)
    assert_includes org.memberships, memberships(:lead_membership)
    assert_includes org.memberships, memberships(:scout_membership)
  end

  test "has many users through memberships" do
    org = organizations(:team_254)
    assert_respond_to org, :users
    assert_includes org.users, users(:admin_user)
  end

  test "has many events" do
    org = organizations(:team_254)
    assert_respond_to org, :events
    assert_includes org.events, events(:championship)
  end

  test "has many scouting_entries" do
    org = organizations(:team_254)
    assert_respond_to org, :scouting_entries
    assert_includes org.scouting_entries, scouting_entries(:entry_qm1_254)
  end

  test "has many pit_scouting_entries" do
    org = organizations(:team_254)
    assert_respond_to org, :pit_scouting_entries
    assert_includes org.pit_scouting_entries, pit_scouting_entries(:pit_254)
  end

  test "has many pick_lists" do
    org = organizations(:team_254)
    assert_respond_to org, :pick_lists
    assert_includes org.pick_lists, pick_lists(:championship_picks)
  end

  test "has many data_conflicts" do
    org = organizations(:team_254)
    assert_respond_to org, :data_conflicts
  end

  test "has many game_configs" do
    org = organizations(:team_254)
    assert_respond_to org, :game_configs
  end

  test "has many predictions" do
    org = organizations(:team_254)
    assert_respond_to org, :predictions
    assert_includes org.predictions, predictions(:prediction_qm1)
  end

  test "has many reports" do
    org = organizations(:team_254)
    assert_respond_to org, :reports
    assert_includes org.reports, reports(:team_summary_report)
  end

  test "has many simulation_results" do
    org = organizations(:team_254)
    assert_respond_to org, :simulation_results
    assert_includes org.simulation_results, simulation_results(:sim_254_vs_1678)
  end

  test "destroying organization destroys dependent memberships" do
    org = organizations(:team_1678)
    # team_1678 has no memberships in fixtures, so create one
    membership = Membership.create!(user: users(:scout_user), organization: org, role: :scout)
    mid = membership.id
    org.destroy
    assert_nil Membership.find_by(id: mid)
  end
end
