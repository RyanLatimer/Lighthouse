require "test_helper"

class PitScoutingEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin_user)
    @event = events(:championship)
    @pit_entry = pit_scouting_entries(:pit_254)
    sign_in_as(@user)
    select_event(@event)
  end

  # --- Index ---

  test "should get index" do
    get pit_scouting_entries_path
    assert_response :success
  end

  test "scout can get index" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get pit_scouting_entries_path
    assert_response :success
  end

  test "index requires event" do
    reset!
    sign_in_as(@user)

    get pit_scouting_entries_path
    assert_redirected_to events_path
  end

  # --- Show ---

  test "should get show" do
    get pit_scouting_entry_path(@pit_entry)
    assert_response :success
  end

  # --- New ---

  test "should get new" do
    get new_pit_scouting_entry_path
    assert_response :success
    assert_select "button", text: /Upload Photos/
    assert_select "button", text: /Take Photos/
    assert_select "video[data-pit-photo-target='video']"
    assert_select "button", text: /Capture Photo/
    assert_select "button", text: /Switch Camera/
  end

  test "scout can get new" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    get new_pit_scouting_entry_path
    assert_response :success
  end

  # --- Create ---

  test "should create pit scouting entry" do
    team = frc_teams(:team_4414)
    photo = Rack::Test::UploadedFile.new(file_fixture("test_photo.jpg"), "image/jpeg")

    assert_difference("PitScoutingEntry.count", 1) do
      post pit_scouting_entries_path, params: {
        pit_scouting_entry: {
          frc_team_id: team.id,
          notes: "Test pit scouting entry",
          client_uuid: "pit-create-test-#{SecureRandom.hex(8)}",
          data: { drivetrain: "tank", robot_weight: 115 },
          photos: [ photo ]
        }
      }
    end
    assert_redirected_to pit_scouting_entry_path(PitScoutingEntry.last)
    assert PitScoutingEntry.last.photos.attached?
  end

  test "scout can create pit scouting entry" do
    sign_out :user
    sign_in_as(users(:scout_user))
    select_event(@event)

    team = frc_teams(:team_118)

    assert_difference("PitScoutingEntry.count", 1) do
      post pit_scouting_entries_path, params: {
        pit_scouting_entry: {
          frc_team_id: team.id,
          notes: "Scout pit entry",
          client_uuid: "scout-pit-create-#{SecureRandom.hex(8)}",
          data: { drivetrain: "swerve" }
        }
      }
    end
    assert_redirected_to pit_scouting_entry_path(PitScoutingEntry.last)
  end

  test "create with duplicate client_uuid redirects to existing" do
    existing = pit_scouting_entries(:pit_254)

    assert_no_difference("PitScoutingEntry.count") do
      post pit_scouting_entries_path, params: {
        pit_scouting_entry: {
          frc_team_id: existing.frc_team_id,
          notes: "Duplicate",
          client_uuid: existing.client_uuid
        }
      }
    end
    assert_redirected_to pit_scouting_entry_path(existing)
  end

  # --- Authentication ---

  test "unauthenticated user is redirected" do
    sign_out :user

    get pit_scouting_entries_path
    assert_redirected_to new_user_session_path
  end
end
