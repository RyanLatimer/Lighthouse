require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @organization = organizations(:team_254)
    sign_in_as(@user)
  end

  # --- Show ---

  test "should get show" do
    get organization_path(@organization)
    assert_response :success
  end

  test "scout can get show" do
    sign_out :user
    sign_in_as(users(:scout_user))

    get organization_path(@organization)
    assert_response :success
  end

  # --- New ---

  test "should get new" do
    get new_organization_path
    assert_response :success
  end

  # --- Create ---

  test "should create organization" do
    assert_difference("Organization.count", 1) do
      post organizations_path, params: {
        organization: {
          name: "Team 9999",
          team_number: 9999
        }
      }
    end
    assert_redirected_to root_path
  end

  test "should create organization and set owner membership" do
    assert_difference("Membership.count", 1) do
      post organizations_path, params: {
        organization: {
          name: "Team 8888",
          team_number: 8888
        }
      }
    end

    new_org = Organization.find_by(team_number: 8888)
    assert new_org.present?
    membership = Membership.find_by(user: @user, organization: new_org)
    assert membership.present?
    assert_equal "owner", membership.role
  end

  test "create with invalid params renders new" do
    assert_no_difference("Organization.count") do
      post organizations_path, params: {
        organization: {
          name: "",
          team_number: nil
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # --- Switch ---

  test "should switch organization" do
    post switch_organization_path(@organization)
    assert_redirected_to root_path
  end

  test "switch to organization user does not belong to" do
    other_org = organizations(:team_1678)

    post switch_organization_path(other_org)
    # Controller redirects to root with alert when org not found for user
    assert_redirected_to root_path
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get organization_path(@organization)
    assert_redirected_to new_user_session_path
  end
end
