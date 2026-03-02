require "test_helper"

class EventTeamTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid event team from fixtures" do
    assert event_teams(:event_team_254).valid?
    assert event_teams(:event_team_1678).valid?
  end

  test "requires unique frc_team per event" do
    duplicate = EventTeam.new(
      event: events(:championship),
      frc_team: frc_teams(:team_254)
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:frc_team_id], "has already been taken"
  end

  test "same team can be at different events" do
    other_event = Event.create!(name: "Other Event", tba_key: "2026other", year: 2026)
    event_team = EventTeam.new(event: other_event, frc_team: frc_teams(:team_254))
    assert event_team.valid?
  end

  # --- Associations ---

  test "belongs to event" do
    assert_equal events(:championship), event_teams(:event_team_254).event
  end

  test "belongs to frc_team" do
    assert_equal frc_teams(:team_254), event_teams(:event_team_254).frc_team
  end

  # --- Fixture data ---

  test "four teams at championship event" do
    assert_equal 4, EventTeam.where(event: events(:championship)).count
  end
end
