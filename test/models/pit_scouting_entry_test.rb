require "test_helper"

class PitScoutingEntryTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid pit scouting entry from fixtures" do
    assert pit_scouting_entries(:pit_254).valid?
    assert pit_scouting_entries(:pit_1678).valid?
  end

  test "requires unique client_uuid" do
    duplicate = PitScoutingEntry.new(
      user: users(:admin_user),
      frc_team: frc_teams(:team_254),
      event: events(:championship),
      client_uuid: "pit-entry-uuid-0001"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:client_uuid], "has already been taken"
  end

  test "allows nil client_uuid" do
    entry = PitScoutingEntry.new(
      user: users(:admin_user),
      frc_team: frc_teams(:team_254),
      event: events(:championship),
      data: {},
      client_uuid: nil
    )
    entry.valid?
    assert_empty entry.errors[:client_uuid]
  end

  # --- Associations ---

  test "belongs to organization (optional)" do
    assert_equal organizations(:team_254), pit_scouting_entries(:pit_254).organization
  end

  test "belongs to event" do
    assert_equal events(:championship), pit_scouting_entries(:pit_254).event
  end

  test "belongs to frc_team" do
    assert_equal frc_teams(:team_254), pit_scouting_entries(:pit_254).frc_team
  end

  test "belongs to user" do
    assert_equal users(:scout_user), pit_scouting_entries(:pit_254).user
  end

  # --- Enums ---

  test "status enum values" do
    assert_equal({ "submitted" => 0, "flagged" => 1, "rejected" => 2 }, PitScoutingEntry.statuses)
  end

  test "pit_254 is submitted" do
    assert pit_scouting_entries(:pit_254).submitted?
  end

  # --- Computed Methods: pit_254 ---
  # Data: drivetrain=swerve, robot_weight=120, robot_width=28, robot_length=30, robot_height=42,
  #        mechanisms=[shooter, intake, climber], auto_capabilities=[4-ball],
  #        strengths="Fast cycle time, reliable climber", weaknesses="Occasional intake jams"

  test "drivetrain for pit_254" do
    assert_equal "swerve", pit_scouting_entries(:pit_254).drivetrain
  end

  test "robot_width for pit_254" do
    assert_equal 28, pit_scouting_entries(:pit_254).robot_width
  end

  test "robot_length for pit_254" do
    assert_equal 30, pit_scouting_entries(:pit_254).robot_length
  end

  test "robot_height for pit_254" do
    assert_equal 42, pit_scouting_entries(:pit_254).robot_height
  end

  test "robot_weight for pit_254" do
    assert_equal 120, pit_scouting_entries(:pit_254).robot_weight
  end

  test "mechanisms for pit_254" do
    assert_equal ["shooter", "intake", "climber"], pit_scouting_entries(:pit_254).mechanisms
  end

  test "auto_capabilities for pit_254" do
    assert_equal ["4-ball"], pit_scouting_entries(:pit_254).auto_capabilities
  end

  test "strengths for pit_254" do
    assert_equal "Fast cycle time, reliable climber", pit_scouting_entries(:pit_254).strengths
  end

  test "weaknesses for pit_254" do
    assert_equal "Occasional intake jams", pit_scouting_entries(:pit_254).weaknesses
  end

  # --- Computed Methods: pit_1678 ---

  test "drivetrain for pit_1678" do
    assert_equal "swerve", pit_scouting_entries(:pit_1678).drivetrain
  end

  test "robot_weight for pit_1678" do
    assert_equal 118, pit_scouting_entries(:pit_1678).robot_weight
  end

  test "mechanisms for pit_1678" do
    assert_equal ["shooter", "intake", "climber"], pit_scouting_entries(:pit_1678).mechanisms
  end

  test "auto_capabilities for pit_1678" do
    assert_equal ["3-ball"], pit_scouting_entries(:pit_1678).auto_capabilities
  end

  test "strengths for pit_1678" do
    assert_equal "Consistent autonomous, great defense", pit_scouting_entries(:pit_1678).strengths
  end

  test "weaknesses for pit_1678" do
    assert_equal "Slower cycle time", pit_scouting_entries(:pit_1678).weaknesses
  end

  # --- Edge cases for computed methods ---

  test "drivetrain returns Unknown when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal "Unknown", entry.drivetrain
  end

  test "robot_width returns nil when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_nil entry.robot_width
  end

  test "mechanisms returns empty array when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal [], entry.mechanisms
  end

  test "auto_capabilities returns empty array when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal [], entry.auto_capabilities
  end

  test "strengths returns empty string when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal "", entry.strengths
  end

  test "weaknesses returns empty string when not present" do
    entry = PitScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal "", entry.weaknesses
  end

  # --- Class Methods ---

  test "from_offline_data builds a new PitScoutingEntry" do
    params = {
      user_id: users(:admin_user).id,
      event_id: events(:championship).id,
      frc_team_id: frc_teams(:team_118).id,
      organization_id: organizations(:team_254).id,
      data: { "drivetrain" => "tank" },
      notes: "Offline pit scout",
      client_uuid: "offline-pit-uuid-001",
      status: :submitted
    }
    entry = PitScoutingEntry.from_offline_data(params)

    assert entry.new_record?
    assert_equal users(:admin_user).id, entry.user_id
    assert_equal events(:championship).id, entry.event_id
    assert_equal frc_teams(:team_118).id, entry.frc_team_id
    assert_equal organizations(:team_254).id, entry.organization_id
    assert_equal({ "drivetrain" => "tank" }, entry.data)
    assert_equal "Offline pit scout", entry.notes
    assert_equal "offline-pit-uuid-001", entry.client_uuid
  end

  test "from_offline_data defaults to empty hash for data" do
    params = {
      user_id: users(:admin_user).id,
      event_id: events(:championship).id,
      frc_team_id: frc_teams(:team_254).id
    }
    entry = PitScoutingEntry.from_offline_data(params)
    assert_equal({}, entry.data)
  end
end
