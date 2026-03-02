require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @team = frc_teams(:team_254)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- Index ---

  test "should get index" do
    get teams_path
    assert_response :success
  end

  test "scout can get index" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get teams_path
    assert_response :success
  end

  test "index requires event" do
    reset!
    sign_in_as(@user)

    get teams_path
    assert_redirected_to events_path
  end

  # --- Show ---

  test "should get show" do
    get team_path(@team)
    assert_response :success
  end

  test "should get show for different team" do
    get team_path(frc_teams(:team_1678))
    assert_response :success
  end

  test "scout can get show" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get team_path(@team)
    assert_response :success
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get teams_path
    assert_redirected_to new_user_session_path
  end
end
