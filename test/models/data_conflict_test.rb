require "test_helper"

class DataConflictTest < ActiveSupport::TestCase
  # --- Fixture validation ---

  test "valid data conflict from fixtures" do
    assert data_conflicts(:conflict_qm1_254_climb).valid?
  end

  # --- Associations ---

  test "belongs to event" do
    assert_equal events(:championship), data_conflicts(:conflict_qm1_254_climb).event
  end

  test "belongs to frc_team" do
    assert_equal frc_teams(:team_254), data_conflicts(:conflict_qm1_254_climb).frc_team
  end

  test "belongs to match" do
    assert_equal matches(:qm1), data_conflicts(:conflict_qm1_254_climb).match
  end

  test "belongs to resolved_by user (optional)" do
    conflict = data_conflicts(:conflict_qm1_254_climb)
    assert_nil conflict.resolved_by
  end

  # --- Scopes ---

  test "unresolved returns conflicts that are not resolved" do
    conflict = data_conflicts(:conflict_qm1_254_climb)
    assert_not conflict.resolved
    assert_includes DataConflict.unresolved, conflict
  end

  test "resolved scope excludes unresolved conflicts" do
    assert_not_includes DataConflict.resolved, data_conflicts(:conflict_qm1_254_climb)
  end

  test "resolved scope returns resolved conflicts" do
    conflict = data_conflicts(:conflict_qm1_254_climb)
    conflict.update!(resolved: true, resolved_by: users(:admin_user), resolution_value: "high")
    assert_includes DataConflict.resolved, conflict
    assert_not_includes DataConflict.unresolved, conflict
  end

  # --- Fixture data ---

  test "conflict has correct field_name" do
    assert_equal "endgame_climb", data_conflicts(:conflict_qm1_254_climb).field_name
  end

  test "conflict is unresolved by default" do
    assert_equal false, data_conflicts(:conflict_qm1_254_climb).resolved
  end
end
