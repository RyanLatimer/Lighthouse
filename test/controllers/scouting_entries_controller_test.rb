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

  # --- Sync with LWW ---

  test "sync creates new entry" do
    uuid = "sync-new-#{SecureRandom.hex(8)}"
    team = frc_teams(:team_4414)
    match = matches(:qm2)

    assert_difference("ScoutingEntry.count", 1) do
      post sync_scouting_entries_path,
        params: {
          entries: [
            {
              client_uuid: uuid,
              match_id: match.id,
              frc_team_id: team.id,
              event_id: @event.id,
              notes: "Synced entry",
              data: { auton_fuel_made: 3 }
            }
          ]
        },
        headers: { "Origin" => "http://www.example.com" },
        as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "created", body["results"][0]["status"]
  end

  test "sync returns existing when duplicate uuid has no updated_at" do
    existing = scouting_entries(:entry_qm1_254)

    assert_no_difference("ScoutingEntry.count") do
      post sync_scouting_entries_path,
        params: {
          entries: [
            {
              client_uuid: existing.client_uuid,
              match_id: existing.match_id,
              frc_team_id: existing.frc_team_id,
              event_id: existing.event_id,
              notes: "Should not overwrite",
              data: { auton_fuel_made: 99 }
            }
          ]
        },
        headers: { "Origin" => "http://www.example.com" },
        as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "existing", body["results"][0]["status"]

    existing.reload
    assert_not_equal 99, existing.data["auton_fuel_made"]
  end

  test "sync updates existing entry when incoming timestamp is newer (LWW)" do
    existing = scouting_entries(:entry_qm1_254)
    future_time = (existing.updated_at + 1.hour).iso8601

    assert_no_difference("ScoutingEntry.count") do
      post sync_scouting_entries_path,
        params: {
          entries: [
            {
              client_uuid: existing.client_uuid,
              match_id: existing.match_id,
              frc_team_id: existing.frc_team_id,
              event_id: existing.event_id,
              notes: "Updated via LWW sync",
              updated_at: future_time,
              data: { auton_fuel_made: 77, teleop_fuel_made: 33 }
            }
          ]
        },
        headers: { "Origin" => "http://www.example.com" },
        as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "updated", body["results"][0]["status"]

    existing.reload
    assert_equal 77, existing.data["auton_fuel_made"]
    assert_equal 33, existing.data["teleop_fuel_made"]
    assert_equal "Updated via LWW sync", existing.notes
  end

  test "sync skips update when server copy is newer" do
    existing = scouting_entries(:entry_qm1_254)
    old_time = (existing.updated_at - 1.hour).iso8601

    post sync_scouting_entries_path,
      params: {
        entries: [
          {
            client_uuid: existing.client_uuid,
            match_id: existing.match_id,
            frc_team_id: existing.frc_team_id,
            event_id: existing.event_id,
            notes: "Should not overwrite",
            updated_at: old_time,
            data: { auton_fuel_made: 88 }
          }
        ]
      },
      headers: { "Origin" => "http://www.example.com" },
      as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "existing", body["results"][0]["status"]

    existing.reload
    assert_not_equal 88, existing.data["auton_fuel_made"]
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get scouting_entries_path
    assert_redirected_to new_user_session_path
  end
end
