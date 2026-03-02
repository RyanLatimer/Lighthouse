require "test_helper"

class UserTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid user from fixtures" do
    assert users(:admin_user).valid?
    assert users(:lead_user).valid?
    assert users(:scout_user).valid?
  end

  test "requires first_name" do
    user = users(:admin_user)
    user.first_name = nil
    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "requires last_name" do
    user = users(:admin_user)
    user.last_name = nil
    assert_not user.valid?
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "requires team_number" do
    user = users(:admin_user)
    user.team_number = nil
    assert_not user.valid?
    assert_includes user.errors[:team_number], "can't be blank"
  end

  test "requires email" do
    user = users(:admin_user)
    user.email = nil
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires unique email" do
    duplicate = users(:admin_user).dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  # --- Associations ---

  test "has many memberships" do
    user = users(:admin_user)
    assert_respond_to user, :memberships
    assert_includes user.memberships, memberships(:admin_membership)
  end

  test "has many organizations through memberships" do
    user = users(:admin_user)
    assert_respond_to user, :organizations
    assert_includes user.organizations, organizations(:team_254)
  end

  test "has many scouting_entries" do
    user = users(:admin_user)
    assert_respond_to user, :scouting_entries
    assert_includes user.scouting_entries, scouting_entries(:entry_qm1_254)
  end

  test "has many pit_scouting_entries" do
    user = users(:scout_user)
    assert_respond_to user, :pit_scouting_entries
    assert_includes user.pit_scouting_entries, pit_scouting_entries(:pit_254)
  end

  test "has many pick_lists" do
    user = users(:admin_user)
    assert_respond_to user, :pick_lists
    assert_includes user.pick_lists, pick_lists(:championship_picks)
  end

  test "has many reports" do
    user = users(:admin_user)
    assert_respond_to user, :reports
    assert_includes user.reports, reports(:team_summary_report)
  end

  test "has many simulation_results" do
    user = users(:admin_user)
    assert_respond_to user, :simulation_results
    assert_includes user.simulation_results, simulation_results(:sim_254_vs_1678)
  end

  test "destroying user destroys dependent memberships" do
    user = User.create!(
      email: "disposable@example.com", password: "password123",
      first_name: "Disposable", last_name: "User", team_number: 999
    )
    membership = Membership.create!(user: user, organization: organizations(:team_254), role: :scout)
    membership_id = membership.id
    user.destroy
    assert_nil Membership.find_by(id: membership_id)
  end

  # --- Callbacks ---

  test "generates api_token before create" do
    user = User.new(
      email: "newuser@example.com",
      password: "password123",
      first_name: "New",
      last_name: "User",
      team_number: 999
    )
    assert_nil user.api_token
    user.save!
    assert_not_nil user.api_token
    assert_equal 64, user.api_token.length
  end

  test "does not overwrite existing api_token on create" do
    user = User.new(
      email: "tokenuser@example.com",
      password: "password123",
      first_name: "Token",
      last_name: "User",
      team_number: 999,
      api_token: "preexisting_token_value"
    )
    user.save!
    assert_equal "preexisting_token_value", user.api_token
  end

  # --- Instance Methods ---

  test "full_name returns first and last name" do
    user = users(:admin_user)
    assert_equal "Admin User", user.full_name
  end

  test "full_name for lead_user" do
    assert_equal "Lead User", users(:lead_user).full_name
  end

  test "role_name returns highest priority Rolify role" do
    assert_equal "admin", users(:admin_user).role_name
    assert_equal "lead", users(:lead_user).role_name
    assert_equal "scout", users(:scout_user).role_name
  end

  test "membership_for returns correct membership" do
    user = users(:admin_user)
    org = organizations(:team_254)
    membership = user.membership_for(org)
    assert_equal memberships(:admin_membership), membership
  end

  test "membership_for returns nil for non-member organization" do
    user = users(:admin_user)
    org = organizations(:team_1678)
    assert_nil user.membership_for(org)
  end

  test "membership_for returns nil when organization is nil" do
    assert_nil users(:admin_user).membership_for(nil)
  end

  test "role_in returns membership role for organization" do
    user = users(:admin_user)
    org = organizations(:team_254)
    assert_equal "admin", user.role_in(org)
  end

  test "role_in returns scout for non-member organization" do
    user = users(:admin_user)
    org = organizations(:team_1678)
    assert_equal "scout", user.role_in(org)
  end

  test "at_least? checks role hierarchy via membership" do
    admin = users(:admin_user)
    org = organizations(:team_254)

    assert admin.at_least?(:scout, org)
    assert admin.at_least?(:lead, org)
    assert admin.at_least?(:admin, org)
    assert_not admin.at_least?(:owner, org)
  end

  test "at_least? returns false for non-member organization" do
    user = users(:admin_user)
    org = organizations(:team_1678)
    assert_not user.at_least?(:scout, org)
  end

  test "admin_of? returns true for admin membership" do
    assert users(:admin_user).admin_of?(organizations(:team_254))
  end

  test "admin_of? returns false for non-admin membership" do
    assert_not users(:scout_user).admin_of?(organizations(:team_254))
  end

  test "lead_of? returns true for lead and above" do
    org = organizations(:team_254)
    assert users(:admin_user).lead_of?(org)
    assert users(:lead_user).lead_of?(org)
    assert_not users(:scout_user).lead_of?(org)
  end

  test "owner_of? returns false when not owner" do
    org = organizations(:team_254)
    assert_not users(:admin_user).owner_of?(org)
  end

  test "regenerate_api_token! updates api_token" do
    user = users(:admin_user)
    old_token = user.api_token
    user.regenerate_api_token!
    assert_not_equal old_token, user.api_token
    assert_equal 64, user.api_token.length
  end
end
