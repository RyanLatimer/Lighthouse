require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid membership from fixtures" do
    assert memberships(:admin_membership).valid?
    assert memberships(:lead_membership).valid?
    assert memberships(:scout_membership).valid?
  end

  test "requires role" do
    membership = Membership.new(
      user: users(:admin_user),
      organization: organizations(:team_1678)
    )
    membership.role = nil
    assert_not membership.valid?
    assert_includes membership.errors[:role], "can't be blank"
  end

  test "requires unique user per organization" do
    duplicate = Membership.new(
      user: users(:admin_user),
      organization: organizations(:team_254),
      role: :scout
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can belong to different organizations" do
    membership = Membership.new(
      user: users(:admin_user),
      organization: organizations(:team_1678),
      role: :scout
    )
    assert membership.valid?
  end

  # --- Associations ---

  test "belongs to user" do
    membership = memberships(:admin_membership)
    assert_equal users(:admin_user), membership.user
  end

  test "belongs to organization" do
    membership = memberships(:admin_membership)
    assert_equal organizations(:team_254), membership.organization
  end

  # --- Enums ---

  test "role enum values" do
    assert_equal({ "scout" => 0, "analyst" => 1, "lead" => 2, "admin" => 3, "owner" => 4 }, Membership.roles)
  end

  test "admin_membership has admin role" do
    assert memberships(:admin_membership).admin?
    assert_equal "admin", memberships(:admin_membership).role
  end

  test "lead_membership has lead role" do
    assert memberships(:lead_membership).lead?
    assert_equal "lead", memberships(:lead_membership).role
  end

  test "scout_membership has scout role" do
    assert memberships(:scout_membership).scout?
    assert_equal "scout", memberships(:scout_membership).role
  end

  # --- Instance Methods ---

  test "at_least? returns true for same role" do
    assert memberships(:admin_membership).at_least?(:admin)
    assert memberships(:lead_membership).at_least?(:lead)
    assert memberships(:scout_membership).at_least?(:scout)
  end

  test "at_least? returns true for lower roles" do
    admin = memberships(:admin_membership)
    assert admin.at_least?(:scout)
    assert admin.at_least?(:analyst)
    assert admin.at_least?(:lead)
    assert admin.at_least?(:admin)
  end

  test "at_least? returns false for higher roles" do
    scout = memberships(:scout_membership)
    assert_not scout.at_least?(:analyst)
    assert_not scout.at_least?(:lead)
    assert_not scout.at_least?(:admin)
    assert_not scout.at_least?(:owner)
  end

  test "at_least? lead can do lead and below" do
    lead = memberships(:lead_membership)
    assert lead.at_least?(:scout)
    assert lead.at_least?(:analyst)
    assert lead.at_least?(:lead)
    assert_not lead.at_least?(:admin)
    assert_not lead.at_least?(:owner)
  end

  test "ROLE_PRIORITY constant" do
    assert_equal %w[scout analyst lead admin owner], Membership::ROLE_PRIORITY
  end
end
