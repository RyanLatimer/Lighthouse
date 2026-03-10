require "test_helper"

class UserShiftStatusServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
  end

  test "returns active shift details when current match is inside a shift" do
    Match.where(event: @event, comp_level: "qm").update_all(red_score: nil, blue_score: nil)

    status = UserShiftStatusService.new(@event, users(:admin_user)).call

    assert_equal :active, status[:state]
    assert_equal matches(:qm1), status[:current_match]
    assert_equal matches(:qm1), status[:shift_start]
    assert_equal matches(:qm2), status[:shift_end]
    assert_equal 2, status[:matches_left_in_shift]
  end

  test "returns upcoming shift details when the next shift has not started" do
    Match.where(event: @event, comp_level: "qm").update_all(red_score: nil, blue_score: nil)
    matches(:qm1).update!(red_score: 180, blue_score: 120)
    ScoutingAssignment.where(event: @event, user: users(:scout_user)).destroy_all
    ScoutingAssignment.create!(event: @event, user: users(:scout_user), match: matches(:qm4))

    status = UserShiftStatusService.new(@event, users(:scout_user)).call

    assert_equal :upcoming, status[:state]
    assert_equal matches(:qm2), status[:current_match]
    assert_equal matches(:qm4), status[:shift_start]
    assert_equal matches(:qm4), status[:shift_end]
    assert_equal 2, status[:matches_until_start]
  end
end
