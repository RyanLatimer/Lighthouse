require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid role from fixtures" do
    assert roles(:admin_role).valid?
    assert roles(:lead_role).valid?
    assert roles(:scout_role).valid?
  end

  test "has and belongs to many users" do
    role = roles(:admin_role)
    assert_respond_to role, :users
    assert_includes role.users, users(:admin_user)
  end

  test "admin role is associated with admin user" do
    assert_includes roles(:admin_role).users, users(:admin_user)
    assert_not_includes roles(:admin_role).users, users(:scout_user)
  end

  test "validates resource_type inclusion" do
    role = Role.new(name: "test", resource_type: "InvalidType")
    assert_not role.valid?
    assert_includes role.errors[:resource_type], "is not included in the list"
  end

  test "allows nil resource_type" do
    role = Role.new(name: "test", resource_type: nil)
    assert role.valid?
  end
end
