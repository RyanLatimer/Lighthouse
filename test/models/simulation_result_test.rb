require "test_helper"

class SimulationResultTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid simulation result from fixtures" do
    assert simulation_results(:sim_254_vs_1678).valid?
  end

  test "requires red_team_ids" do
    sim = simulation_results(:sim_254_vs_1678)
    sim.red_team_ids = nil
    assert_not sim.valid?
    assert_includes sim.errors[:red_team_ids], "can't be blank"
  end

  test "requires blue_team_ids" do
    sim = simulation_results(:sim_254_vs_1678)
    sim.blue_team_ids = nil
    assert_not sim.valid?
    assert_includes sim.errors[:blue_team_ids], "can't be blank"
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:admin_user), simulation_results(:sim_254_vs_1678).user
  end

  test "belongs to event" do
    assert_equal events(:championship), simulation_results(:sim_254_vs_1678).event
  end

  # --- Computed Methods ---
  # Test with a properly-built SimulationResult that has Hash results

  test "red_avg from results" do
    sim = build_simulation_result
    assert_equal 87.3, sim.red_avg
  end

  test "blue_avg from results" do
    sim = build_simulation_result
    assert_equal 71.5, sim.blue_avg
  end

  test "red_win_pct from results" do
    sim = build_simulation_result
    assert_equal 72.4, sim.red_win_pct
  end

  test "blue_win_pct from results" do
    sim = build_simulation_result
    assert_equal 27.6, sim.blue_win_pct
  end

  test "margin_of_victory from results" do
    sim = build_simulation_result
    assert_equal 15.8, sim.margin_of_victory
  end

  # --- red_teams and blue_teams ---

  test "red_teams returns FrcTeam relation" do
    sim = SimulationResult.new(
      red_team_ids: [ frc_teams(:team_254).id, frc_teams(:team_4414).id ],
      blue_team_ids: [ frc_teams(:team_1678).id ],
      results: {},
      event: events(:championship),
      user: users(:admin_user)
    )
    red = sim.red_teams
    assert_kind_of ActiveRecord::Relation, red
    assert_includes red, frc_teams(:team_254)
    assert_includes red, frc_teams(:team_4414)
  end

  test "blue_teams returns FrcTeam relation" do
    sim = SimulationResult.new(
      red_team_ids: [ frc_teams(:team_254).id ],
      blue_team_ids: [ frc_teams(:team_1678).id ],
      results: {},
      event: events(:championship),
      user: users(:admin_user)
    )
    blue = sim.blue_teams
    assert_kind_of ActiveRecord::Relation, blue
    assert_includes blue, frc_teams(:team_1678)
  end

  # --- Edge cases ---

  test "red_avg returns 0.0 when results is empty" do
    sim = SimulationResult.new(results: {})
    assert_equal 0.0, sim.red_avg
  end

  test "blue_avg returns 0.0 when results is empty" do
    sim = SimulationResult.new(results: {})
    assert_equal 0.0, sim.blue_avg
  end

  test "red_win_pct returns 0.0 when results is nil" do
    sim = SimulationResult.new(results: nil)
    assert_equal 0.0, sim.red_win_pct
  end

  test "blue_win_pct returns 0.0 when results is nil" do
    sim = SimulationResult.new(results: nil)
    assert_equal 0.0, sim.blue_win_pct
  end

  test "margin_of_victory returns 0.0 when results is empty" do
    sim = SimulationResult.new(results: {})
    assert_equal 0.0, sim.margin_of_victory
  end

  private

  def build_simulation_result
    SimulationResult.new(
      red_team_ids: [ 254, 4414, 118 ],
      blue_team_ids: [ 1678 ],
      results: {
        "red_avg" => 87.3,
        "blue_avg" => 71.5,
        "red_win_pct" => 72.4,
        "blue_win_pct" => 27.6,
        "margin_of_victory" => 15.8
      },
      event: events(:championship),
      user: users(:admin_user)
    )
  end
end
