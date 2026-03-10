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

  test "should redirect to events without event selected" do
    get root_path
    assert_response :redirect
    assert_redirected_to events_path
  end

  test "should redirect to sign in when not authenticated" do
    sign_out :user

    get root_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "any role redirects to events without event" do
    sign_out :user
    sign_in_as(users(:scout_user))

    get root_path
    assert_response :redirect
    assert_redirected_to events_path
  end

  test "any role can access dashboard with event" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get root_path
    assert_response :success
  end

  test "dashboard displays scout accuracy leaderboard" do
    select_event(@event)

    get root_path
    assert_response :success
    assert_select "h2", text: "Scout Accuracy Leaderboard"
  end

  test "dashboard shows accuracy data for scouts with scored matches" do
    select_event(@event)

    get root_path
    assert_response :success
    assert_match(/pts off/, response.body)
  end

  test "dashboard shows active shift status for the current user" do
    Match.where(event: @event, comp_level: "qm").update_all(red_score: nil, blue_score: nil)
    select_event(@event)

    get root_path
    assert_response :success
    assert_match "My Shift", response.body
    assert_match "Current: Q1", response.body
    assert_match "2 matches left in shift", response.body
  end

  test "dashboard shows upcoming shift start and matches until it begins" do
    Match.where(event: @event, comp_level: "qm").update_all(red_score: nil, blue_score: nil)
    matches(:qm1).update!(red_score: 180, blue_score: 120)
    ScoutingAssignment.where(event: @event, user: @user).destroy_all
    ScoutingAssignment.create!(event: @event, user: @user, match: matches(:qm4))
    select_event(@event)

    get root_path
    assert_response :success
    assert_match "Current: Q2", response.body
    assert_match "Starts in 2 matches", response.body
    assert_match "Q4", response.body
  end
end
