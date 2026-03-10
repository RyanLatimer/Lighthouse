require "test_helper"

class ScoutableMatchesQueryTest < ActiveSupport::TestCase
  test "live returns only future matches" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 10:30:00")).live

    assert_equal [ matches(:qm2), matches(:qm3) ], matches
  end

  test "live returns no matches after the event has ended" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-20 12:00:00")).live

    assert_empty matches
  end

  test "replay returns played matches with videos most recent first" do
    matches = ScoutableMatchesQuery.new(events(:championship), reference_time: Time.zone.parse("2026-04-15 11:00:00")).replay

    assert_equal [ matches(:qm4), matches(:qm1) ], matches.select(&:replay_available?)
  end

  test "only qualification matches are scoutable" do
    event = events(:championship)
    playoff_match = event.matches.create!(
      comp_level: "qf",
      set_number: 1,
      match_number: 1,
      scheduled_time: Time.zone.parse("2026-04-15 12:00:00"),
      actual_time: Time.zone.parse("2026-04-15 12:05:00"),
      post_result_time: Time.zone.parse("2026-04-15 12:10:00"),
      videos: [ { "type" => "youtube", "key" => "playoffvideo" } ]
    )

    query = ScoutableMatchesQuery.new(event, reference_time: Time.zone.parse("2026-04-15 12:30:00"))

    assert_not_includes query.live, playoff_match
    assert_not_includes query.replay, playoff_match
  end
end
