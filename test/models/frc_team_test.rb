require "test_helper"

class FrcTeamTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid frc_team from fixtures" do
    assert frc_teams(:team_254).valid?
    assert frc_teams(:team_1678).valid?
    assert frc_teams(:team_4414).valid?
    assert frc_teams(:team_118).valid?
  end

  test "requires team_number" do
    team = FrcTeam.new(nickname: "Test Team")
    assert_not team.valid?
    assert_includes team.errors[:team_number], "can't be blank"
  end

  test "requires unique team_number" do
    duplicate = FrcTeam.new(team_number: 254, nickname: "Duplicate")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:team_number], "has already been taken"
  end

  # --- Associations ---

  test "has many event_teams" do
    team = frc_teams(:team_254)
    assert_respond_to team, :event_teams
  end

  test "has many events through event_teams" do
    team = frc_teams(:team_254)
    assert_respond_to team, :events
    assert_includes team.events, events(:championship)
  end

  test "has many match_alliances" do
    team = frc_teams(:team_254)
    assert_respond_to team, :match_alliances
    assert_includes team.match_alliances, match_alliances(:qm1_red_1)
  end

  test "has many matches through match_alliances" do
    team = frc_teams(:team_254)
    assert_respond_to team, :matches
    assert_includes team.matches, matches(:qm1)
    assert_includes team.matches, matches(:qm2)
  end

  test "has many scouting_entries" do
    team = frc_teams(:team_254)
    assert_respond_to team, :scouting_entries
    assert_includes team.scouting_entries, scouting_entries(:entry_qm1_254)
    assert_includes team.scouting_entries, scouting_entries(:entry_qm2_254)
  end

  test "has many pit_scouting_entries" do
    team = frc_teams(:team_254)
    assert_respond_to team, :pit_scouting_entries
    assert_includes team.pit_scouting_entries, pit_scouting_entries(:pit_254)
  end

  # --- Scopes ---

  test "at_event returns teams at a specific event" do
    teams = FrcTeam.at_event(events(:championship))
    assert_includes teams, frc_teams(:team_254)
    assert_includes teams, frc_teams(:team_1678)
    assert_includes teams, frc_teams(:team_4414)
    assert_includes teams, frc_teams(:team_118)
  end

  # --- Instance Methods ---

  test "tba_key returns frc prefix with team number" do
    assert_equal "frc254", frc_teams(:team_254).tba_key
    assert_equal "frc1678", frc_teams(:team_1678).tba_key
    assert_equal "frc4414", frc_teams(:team_4414).tba_key
    assert_equal "frc118", frc_teams(:team_118).tba_key
  end

  # --- Dependent destroy ---

  test "destroying frc_team destroys dependent scouting_entries" do
    team = FrcTeam.create!(team_number: 9999, nickname: "Temp Team")
    entry = ScoutingEntry.create!(
      user: users(:admin_user), frc_team: team,
      event: events(:championship), data: {}
    )
    entry_id = entry.id
    team.destroy
    assert_nil ScoutingEntry.find_by(id: entry_id)
  end

  test "destroying frc_team destroys dependent match_alliances" do
    team = FrcTeam.create!(team_number: 9998, nickname: "Temp Team 2")
    event = Event.create!(name: "Temp", tba_key: "2026tmpdestroy", year: 2026)
    match = Match.create!(event: event, comp_level: "qm", match_number: 1, set_number: 1)
    alliance = MatchAlliance.create!(match: match, frc_team: team, alliance_color: "red", station: 1)
    alliance_id = alliance.id
    team.destroy
    assert_nil MatchAlliance.find_by(id: alliance_id)
  end
end
