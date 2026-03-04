require "test_helper"

class Api::V1::ScoutingEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @match = matches(:qm1)
    @team = frc_teams(:team_254)
    @api_token = @user.api_token
  end

  # --- Create ---

  test "should create scouting entry with valid token" do
    # Use team_4414 to avoid unique constraint with existing fixtures
    api_team = frc_teams(:team_4414)

    assert_difference("ScoutingEntry.count", 1) do
      post api_v1_scouting_entries_path, params: {
        scouting_entry: {
          match_id: @match.id,
          frc_team_id: api_team.id,
          event_id: @event.id,
          notes: "API created entry",
          client_uuid: "api-create-#{SecureRandom.hex(8)}",
          data: { auton_fuel_made: 5, teleop_fuel_made: 10 }
        }
      }, headers: { "Authorization" => "Bearer #{@api_token}" }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "created", json["status"]
    assert json["id"].present?
  end

  test "should return unauthorized without token" do
    post api_v1_scouting_entries_path, params: {
      scouting_entry: {
        match_id: @match.id,
        frc_team_id: @team.id,
        event_id: @event.id,
        notes: "No auth"
      }
    }, as: :json

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Unauthorized. Provide a valid Bearer token.", json["error"]
  end

  test "should return unauthorized with invalid token" do
    post api_v1_scouting_entries_path, params: {
      scouting_entry: {
        match_id: @match.id,
        frc_team_id: @team.id,
        event_id: @event.id,
        notes: "Bad token"
      }
    }, headers: { "Authorization" => "Bearer invalid_token_here" }, as: :json

    assert_response :unauthorized
  end

  test "should return existing for duplicate client_uuid" do
    existing = scouting_entries(:entry_qm1_254)

    assert_no_difference("ScoutingEntry.count") do
      post api_v1_scouting_entries_path, params: {
        scouting_entry: {
          match_id: existing.match_id,
          frc_team_id: existing.frc_team_id,
          event_id: existing.event_id,
          client_uuid: existing.client_uuid,
          notes: "Duplicate"
        }
      }, headers: { "Authorization" => "Bearer #{@api_token}" }, as: :json
    end

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "existing", json["status"]
    assert_equal existing.id, json["id"]
  end

  test "should associate entry with api user" do
    # Use team_118 to avoid unique constraint with existing fixtures
    api_team = frc_teams(:team_118)

    post api_v1_scouting_entries_path, params: {
      scouting_entry: {
        match_id: @match.id,
        frc_team_id: api_team.id,
        event_id: @event.id,
        client_uuid: "api-user-check-#{SecureRandom.hex(8)}",
        data: {}
      }
    }, headers: { "Authorization" => "Bearer #{@api_token}" }, as: :json

    assert_response :created
    entry = ScoutingEntry.find(JSON.parse(response.body)["id"])
    assert_equal @user.id, entry.user_id
  end

  # --- Bulk Sync ---

  test "should bulk sync multiple entries" do
    assert_difference("ScoutingEntry.count", 2) do
      post bulk_sync_api_v1_scouting_entries_path, params: {
        entries: [
          {
            match_id: @match.id,
            frc_team_id: frc_teams(:team_4414).id,
            event_id: @event.id,
            client_uuid: "bulk-1-#{SecureRandom.hex(8)}",
            data: { auton_fuel_made: 3 }
          },
          {
            match_id: @match.id,
            frc_team_id: frc_teams(:team_118).id,
            event_id: @event.id,
            client_uuid: "bulk-2-#{SecureRandom.hex(8)}",
            data: { auton_fuel_made: 4 }
          }
        ]
      }, headers: { "Authorization" => "Bearer #{@api_token}" }, as: :json
    end

    json = JSON.parse(response.body)
    assert_equal 2, json["results"].length
    assert json["results"].all? { |r| r["status"] == "created" }
  end

  test "bulk sync skips existing client_uuids" do
    existing = scouting_entries(:entry_qm1_254)

    assert_no_difference("ScoutingEntry.count") do
      post bulk_sync_api_v1_scouting_entries_path, params: {
        entries: [
          {
            match_id: existing.match_id,
            frc_team_id: existing.frc_team_id,
            event_id: existing.event_id,
            client_uuid: existing.client_uuid,
            notes: "Already exists"
          }
        ]
      }, headers: { "Authorization" => "Bearer #{@api_token}" }, as: :json
    end

    json = JSON.parse(response.body)
    assert_equal "existing", json["results"].first["status"]
  end

  test "bulk sync requires authentication" do
    post bulk_sync_api_v1_scouting_entries_path, params: {
      entries: []
    }, as: :json

    assert_response :unauthorized
  end

  # --- Different user tokens ---

  test "scout user can create via api" do
    scout = users(:scout_user)

    assert_difference("ScoutingEntry.count", 1) do
      post api_v1_scouting_entries_path, params: {
        scouting_entry: {
          match_id: @match.id,
          frc_team_id: @team.id,
          event_id: @event.id,
          client_uuid: "scout-api-#{SecureRandom.hex(8)}",
          data: { auton_fuel_made: 2 }
        }
      }, headers: { "Authorization" => "Bearer #{scout.api_token}" }, as: :json
    end

    assert_response :created
    entry = ScoutingEntry.find(JSON.parse(response.body)["id"])
    assert_equal scout.id, entry.user_id
  end
end
