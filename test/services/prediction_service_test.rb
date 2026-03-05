# frozen_string_literal: true

require "test_helper"

class PredictionServiceTest < ActiveSupport::TestCase
  setup do
    @event = events(:championship)
    @service = PredictionService.new(@event)
  end

  test "predict_match returns a saved Prediction record" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction = @service.predict_match(match, red_teams, blue_teams)

    assert_instance_of Prediction, prediction
    assert prediction.persisted?
    assert_equal match, prediction.match
    assert_equal @event, prediction.event
    assert_equal "blended", prediction.source
  end

  test "predict_match sets score and probability fields" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction = @service.predict_match(match, red_teams, blue_teams)

    assert prediction.red_score.present?
    assert prediction.blue_score.present?
    assert prediction.red_win_probability.present?
    assert prediction.blue_win_probability.present?
    assert prediction.red_score >= 0
    assert prediction.blue_score >= 0
  end

  test "predict_match stores scouting details" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction = @service.predict_match(match, red_teams, blue_teams)
    details = prediction.details

    assert details.key?("scouting"), "Details should include scouting data"
    assert details.key?("weights"),  "Details should include weights"
    assert details.key?("red_teams")
    assert details.key?("blue_teams")
  end

  test "predict_match falls back to scouting-only when statbotics is unavailable" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction = @service.predict_match(match, red_teams, blue_teams)

    # Statbotics will fail in test env (no real API), so statbotics should be nil
    assert_nil prediction.details["statbotics"],
              "Statbotics should be nil in test environment (no API access)"
  end

  test "predict_match is idempotent — updates existing prediction" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction1 = @service.predict_match(match, red_teams, blue_teams)
    prediction2 = @service.predict_match(match, red_teams, blue_teams)

    assert_equal prediction1.id, prediction2.id, "Should update the same prediction record"
  end

  test "generate_all! creates predictions for matches with alliances" do
    count = @service.generate_all!

    # qm1 has red and blue alliances, qm2 has red and blue alliances
    assert count >= 1, "Should generate at least 1 prediction"
    assert Prediction.for_event(@event).exists?
  end

  test "generate_all! returns count of predictions created" do
    count = @service.generate_all!
    assert_kind_of Integer, count
    assert count >= 0
  end

  test "prediction win probabilities sum to approximately 100" do
    match = matches(:qm1)
    red_teams = [ frc_teams(:team_254) ]
    blue_teams = [ frc_teams(:team_1678) ]

    prediction = @service.predict_match(match, red_teams, blue_teams)

    total = prediction.red_win_probability + prediction.blue_win_probability
    assert_in_delta 100.0, total, 0.2, "Win probabilities should sum to ~100"
  end
end
