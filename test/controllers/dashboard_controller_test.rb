require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    sign_in_as(@user)
  end

  test "should get index with event selected" do
    select_event(@event)

    get root_path
    assert_response :success
  end

  test "should get index without event selected" do
    get root_path
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    sign_out :user

    get root_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "any role can access dashboard without event" do
    sign_out :user
    sign_in_as(users(:scout_user))

    get root_path
    assert_response :success
  end

  test "any role can access dashboard with event" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get root_path
    assert_response :success
  end
end
