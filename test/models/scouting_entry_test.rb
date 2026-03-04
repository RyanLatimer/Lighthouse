require "test_helper"

class ScoutingEntryTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid scouting entry from fixtures" do
    assert scouting_entries(:entry_qm1_254).valid?
    assert scouting_entries(:entry_qm1_1678).valid?
    assert scouting_entries(:entry_qm2_254).valid?
    assert scouting_entries(:entry_qm2_1678).valid?
  end

  test "requires unique client_uuid" do
    duplicate = ScoutingEntry.new(
      user: users(:admin_user),
      frc_team: frc_teams(:team_254),
      event: events(:championship),
      client_uuid: "scout-entry-uuid-0001"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:client_uuid], "has already been taken"
  end

  test "allows nil client_uuid" do
    entry = ScoutingEntry.new(
      user: users(:admin_user),
      frc_team: frc_teams(:team_254),
      event: events(:championship),
      data: {},
      client_uuid: nil
    )
    entry.valid?
    assert_empty entry.errors[:client_uuid]
  end

  test "allows multiple nil client_uuids" do
    entry1 = ScoutingEntry.create!(
      user: users(:admin_user),
      frc_team: frc_teams(:team_254),
      event: events(:championship),
      data: {},
      client_uuid: nil
    )
    entry2 = ScoutingEntry.new(
      user: users(:lead_user),
      frc_team: frc_teams(:team_1678),
      event: events(:championship),
      data: {},
      client_uuid: nil
    )
    assert entry2.valid?
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:admin_user), scouting_entries(:entry_qm1_254).user
  end

  test "belongs to match (optional)" do
    assert_equal matches(:qm1), scouting_entries(:entry_qm1_254).match
  end

  test "belongs to frc_team" do
    assert_equal frc_teams(:team_254), scouting_entries(:entry_qm1_254).frc_team
  end

  test "belongs to event" do
    assert_equal events(:championship), scouting_entries(:entry_qm1_254).event
  end

  # --- Enums ---

  test "status enum values" do
    assert_equal({ "submitted" => 0, "flagged" => 1, "rejected" => 2 }, ScoutingEntry.statuses)
  end

  test "entry_qm1_254 is submitted" do
    assert scouting_entries(:entry_qm1_254).submitted?
  end

  # --- Scoring concern constants ---

  test "FUEL_POINT_VALUE is 1" do
    assert_equal 1, ScoutingEntry::FUEL_POINT_VALUE
  end

  test "CLIMB_POINTS hash" do
    expected = { "None" => 0, "L1" => 10, "L2" => 20, "L3" => 30 }
    assert_equal expected, ScoutingEntry::CLIMB_POINTS
  end

  test "AUTON_CLIMB_POINTS is 15" do
    assert_equal 15, ScoutingEntry::AUTON_CLIMB_POINTS
  end

  # --- Computed Methods: entry_qm1_254 ---
  # Data: auton_fuel_made=5, auton_fuel_missed=1, teleop_fuel_made=12, teleop_fuel_missed=3,
  #        endgame_fuel_made=0, endgame_fuel_missed=0, endgame_climb=L3, auton_climb=true

  test "total_fuel_made for entry_qm1_254" do
    entry = scouting_entries(:entry_qm1_254)
    # 5 + 12 + 0 = 17
    assert_equal 17, entry.total_fuel_made
  end

  test "total_fuel_missed for entry_qm1_254" do
    entry = scouting_entries(:entry_qm1_254)
    # 1 + 3 + 0 = 4
    assert_equal 4, entry.total_fuel_missed
  end

  test "fuel_accuracy for entry_qm1_254" do
    entry = scouting_entries(:entry_qm1_254)
    # 17 / (17 + 4) * 100 = 17/21*100 = 80.952... -> 81.0
    assert_equal 81.0, entry.fuel_accuracy
  end

  test "total_points for entry_qm1_254" do
    entry = scouting_entries(:entry_qm1_254)
    # fuel: 17 * 1 = 17
    # auton_climb: true -> +15
    # endgame_climb: L3 -> +30
    # total: 17 + 15 + 30 = 62
    assert_equal 62, entry.total_points
  end

  # --- Computed Methods: entry_qm1_1678 ---
  # Data: auton_fuel_made=3, auton_fuel_missed=2, teleop_fuel_made=10, teleop_fuel_missed=4,
  #        endgame_fuel_made=0, endgame_fuel_missed=0, endgame_climb=L2, auton_climb=false

  test "total_fuel_made for entry_qm1_1678" do
    entry = scouting_entries(:entry_qm1_1678)
    # 3 + 10 + 0 = 13
    assert_equal 13, entry.total_fuel_made
  end

  test "total_fuel_missed for entry_qm1_1678" do
    entry = scouting_entries(:entry_qm1_1678)
    # 2 + 4 + 0 = 6
    assert_equal 6, entry.total_fuel_missed
  end

  test "fuel_accuracy for entry_qm1_1678" do
    entry = scouting_entries(:entry_qm1_1678)
    # 13 / (13 + 6) * 100 = 13/19*100 = 68.421... -> 68.4
    assert_equal 68.4, entry.fuel_accuracy
  end

  test "total_points for entry_qm1_1678" do
    entry = scouting_entries(:entry_qm1_1678)
    # fuel: 13 * 1 = 13
    # auton_climb: false -> 0
    # endgame_climb: L2 -> +20
    # total: 13 + 0 + 20 = 33
    assert_equal 33, entry.total_points
  end

  # --- Computed Methods: entry_qm2_254 ---
  # Data: auton_fuel_made=6, auton_fuel_missed=0, teleop_fuel_made=14, teleop_fuel_missed=2,
  #        endgame_fuel_made=0, endgame_fuel_missed=0, endgame_climb=L3, auton_climb=true

  test "total_fuel_made for entry_qm2_254" do
    entry = scouting_entries(:entry_qm2_254)
    # 6 + 14 + 0 = 20
    assert_equal 20, entry.total_fuel_made
  end

  test "total_fuel_missed for entry_qm2_254" do
    entry = scouting_entries(:entry_qm2_254)
    # 0 + 2 + 0 = 2
    assert_equal 2, entry.total_fuel_missed
  end

  test "fuel_accuracy for entry_qm2_254" do
    entry = scouting_entries(:entry_qm2_254)
    # 20 / (20 + 2) * 100 = 20/22*100 = 90.909... -> 90.9
    assert_equal 90.9, entry.fuel_accuracy
  end

  test "total_points for entry_qm2_254" do
    entry = scouting_entries(:entry_qm2_254)
    # fuel: 20 * 1 = 20
    # auton_climb: true -> +15
    # endgame_climb: L3 -> +30
    # total: 20 + 15 + 30 = 65
    assert_equal 65, entry.total_points
  end

  # --- Computed Methods: entry_qm2_1678 ---
  # Data: auton_fuel_made=4, auton_fuel_missed=1, teleop_fuel_made=11, teleop_fuel_missed=3,
  #        endgame_fuel_made=0, endgame_fuel_missed=0, endgame_climb=L2, auton_climb=true

  test "total_fuel_made for entry_qm2_1678" do
    entry = scouting_entries(:entry_qm2_1678)
    # 4 + 11 + 0 = 15
    assert_equal 15, entry.total_fuel_made
  end

  test "total_fuel_missed for entry_qm2_1678" do
    entry = scouting_entries(:entry_qm2_1678)
    # 1 + 3 + 0 = 4
    assert_equal 4, entry.total_fuel_missed
  end

  test "fuel_accuracy for entry_qm2_1678" do
    entry = scouting_entries(:entry_qm2_1678)
    # 15 / (15 + 4) * 100 = 15/19*100 = 78.947... -> 78.9
    assert_equal 78.9, entry.fuel_accuracy
  end

  test "total_points for entry_qm2_1678" do
    entry = scouting_entries(:entry_qm2_1678)
    # fuel: 15 * 1 = 15
    # auton_climb: true -> +15
    # endgame_climb: L2 -> +20
    # total: 15 + 15 + 20 = 50
    assert_equal 50, entry.total_points
  end

  # --- Edge cases for computed methods ---

  test "fuel_accuracy returns 0.0 when no attempts" do
    entry = ScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal 0.0, entry.fuel_accuracy
  end

  test "total_points with no data" do
    entry = ScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal 0, entry.total_points
  end

  test "total_points with unknown climb level" do
    entry = ScoutingEntry.new(
      data: { "endgame_climb" => "Unknown", "auton_climb" => false },
      event: events(:championship),
      frc_team: frc_teams(:team_254),
      user: users(:admin_user)
    )
    assert_equal 0, entry.total_points
  end

  # --- Defense Rating ---

  test "defense_rating returns 0 when not present" do
    entry = ScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal 0, entry.defense_rating
  end

  test "defense_rating returns value from JSONB data" do
    entry = ScoutingEntry.new(
      data: { "defense_rating" => 4 },
      event: events(:championship),
      frc_team: frc_teams(:team_254),
      user: users(:admin_user)
    )
    assert_equal 4, entry.defense_rating
  end

  test "auton_actions returns empty array when not present" do
    entry = ScoutingEntry.new(data: {}, event: events(:championship), frc_team: frc_teams(:team_254), user: users(:admin_user))
    assert_equal [], entry.auton_actions
  end

  test "auton_actions returns data from JSONB" do
    entry = ScoutingEntry.new(
      data: { "auton_actions" => ["move", "shoot", "intake"] },
      event: events(:championship),
      frc_team: frc_teams(:team_254),
      user: users(:admin_user)
    )
    assert_equal ["move", "shoot", "intake"], entry.auton_actions
  end

  # --- Class Methods ---

  test "from_offline_data builds a new ScoutingEntry" do
    params = {
      user_id: users(:admin_user).id,
      match_id: matches(:qm1).id,
      frc_team_id: frc_teams(:team_254).id,
      event_id: events(:championship).id,
      data: { "auton_fuel_made" => 10 },
      notes: "Offline entry",
      photo_url: "https://example.com/photo.jpg",
      client_uuid: "offline-uuid-001",
      status: :submitted
    }
    entry = ScoutingEntry.from_offline_data(params)

    assert entry.new_record?
    assert_equal users(:admin_user).id, entry.user_id
    assert_equal matches(:qm1).id, entry.match_id
    assert_equal frc_teams(:team_254).id, entry.frc_team_id
    assert_equal events(:championship).id, entry.event_id
    assert_equal({ "auton_fuel_made" => 10 }, entry.data)
    assert_equal "Offline entry", entry.notes
    assert_equal "https://example.com/photo.jpg", entry.photo_url
    assert_equal "offline-uuid-001", entry.client_uuid
  end

  test "from_offline_data defaults to empty hash for data and submitted status" do
    params = {
      user_id: users(:admin_user).id,
      frc_team_id: frc_teams(:team_254).id,
      event_id: events(:championship).id
    }
    entry = ScoutingEntry.from_offline_data(params)
    assert_equal({}, entry.data)
  end
end
