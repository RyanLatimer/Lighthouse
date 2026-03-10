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
end
