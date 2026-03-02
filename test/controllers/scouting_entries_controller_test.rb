require "test_helper"

class ScoutingEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @entry = scouting_entries(:entry_qm1_254)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- Index ---

  test "should get index" do
    get scouting_entries_path
    assert_response :success
  end

  test "scout can get index" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get scouting_entries_path
    assert_response :success
  end

  test "index requires event" do
    reset!
    sign_in_as(@user)

    get scouting_entries_path
    assert_redirected_to events_path
  end

  # --- Show ---

  test "should get show" do
    get scouting_entry_path(@entry)
    assert_response :success
  end

  # --- New ---

  test "should get new" do
    get new_scouting_entry_path
    assert_response :success
  end

  test "scout can get new" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get new_scouting_entry_path
    assert_response :success
  end

  # --- Create ---

  test "should create scouting entry" do
    match = matches(:qm2)
    team = frc_teams(:team_4414)

    assert_difference("ScoutingEntry.count", 1) do
      post scouting_entries_path, params: {
        scouting_entry: {
          match_id: match.id,
          frc_team_id: team.id,
          notes: "Test entry",
          client_uuid: "create-test-uuid-#{SecureRandom.hex(8)}",
          data: { auton_fuel_made: 3, teleop_fuel_made: 10 }
        }
      }
    end
    assert_redirected_to scouting_entry_path(ScoutingEntry.last)
  end

  test "scout can create scouting entry" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    match = matches(:qm1)
    team = frc_teams(:team_4414)

    assert_difference("ScoutingEntry.count", 1) do
      post scouting_entries_path, params: {
        scouting_entry: {
          match_id: match.id,
          frc_team_id: team.id,
          notes: "Scout test entry",
          client_uuid: "scout-create-uuid-#{SecureRandom.hex(8)}",
          data: { auton_fuel_made: 1 }
        }
      }
    end
    assert_redirected_to scouting_entry_path(ScoutingEntry.last)
  end

  test "create with duplicate client_uuid redirects to existing" do
    existing = scouting_entries(:entry_qm1_254)

    assert_no_difference("ScoutingEntry.count") do
      post scouting_entries_path, params: {
        scouting_entry: {
          match_id: existing.match_id,
          frc_team_id: existing.frc_team_id,
          notes: "Duplicate",
          client_uuid: existing.client_uuid
        }
      }
    end
    assert_redirected_to scouting_entry_path(existing)
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get scouting_entries_path
    assert_redirected_to new_user_session_path
  end
end
