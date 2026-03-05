require "test_helper"

class MatchSimulatorControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- New ---

  test "should get new" do
    get new_match_simulator_path
    assert_response :success
  end

  test "lead can get new" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    get new_match_simulator_path
    assert_response :success
  end

  test "scout cannot get new" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get new_match_simulator_path
    assert_response :redirect
  end

  test "new requires event" do
    reset!
    sign_in_as(@user)

    get new_match_simulator_path
    assert_redirected_to events_path
  end

  # --- Create ---

  test "should create simulation with team IDs" do
    red_teams = [ frc_teams(:team_254).id, frc_teams(:team_4414).id, frc_teams(:team_118).id ]
    blue_teams = [ frc_teams(:team_1678).id ]

    post match_simulator_path, params: {
      red_team_ids: red_teams.map(&:to_s),
      blue_team_ids: blue_teams.map(&:to_s),
      iterations: 100
    }
    assert_response :success
  end

  test "lead can create simulation" do
    sign_out :user
    sign_in_as(users(:lead_user))
    select_event(@event)

    post match_simulator_path, params: {
      red_team_ids: [ frc_teams(:team_254).id.to_s ],
      blue_team_ids: [ frc_teams(:team_1678).id.to_s ],
      iterations: 100
    }
    assert_response :success
  end

  test "scout cannot create simulation" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    post match_simulator_path, params: {
      red_team_ids: [ frc_teams(:team_254).id.to_s ],
      blue_team_ids: [ frc_teams(:team_1678).id.to_s ]
    }
    assert_response :redirect
  end

  test "create with empty teams still works" do
    post match_simulator_path, params: {
      red_team_ids: [],
      blue_team_ids: []
    }
    assert_response :success
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get new_match_simulator_path
    assert_redirected_to new_user_session_path
  end
end
