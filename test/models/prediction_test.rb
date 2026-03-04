require "test_helper"

class PredictionTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid prediction from fixtures" do
    assert predictions(:prediction_qm1).valid?
  end

  test "requires source" do
    prediction = predictions(:prediction_qm1)
    prediction.source = nil
    assert_not prediction.valid?
    assert_includes prediction.errors[:source], "can't be blank"
  end

  test "source must be scouting, statbotics, or blended" do
    prediction = predictions(:prediction_qm1)

    prediction.source = "scouting"
    assert prediction.valid?

    prediction.source = "statbotics"
    assert prediction.valid?

    prediction.source = "blended"
    assert prediction.valid?

    prediction.source = "invalid"
    assert_not prediction.valid?
    assert_includes prediction.errors[:source], "is not included in the list"
  end

  # --- Associations ---

  test "belongs to match" do
    assert_equal matches(:qm1), predictions(:prediction_qm1).match
  end

  test "belongs to event" do
    assert_equal events(:championship), predictions(:prediction_qm1).event
  end

  # --- Scopes ---

  test "for_event returns predictions for a specific event" do
    assert_includes Prediction.for_event(events(:championship)), predictions(:prediction_qm1)
  end

  test "blended scope returns blended predictions" do
    # prediction_qm1 has source "scouting"
    assert_not_includes Prediction.blended, predictions(:prediction_qm1)
  end

  # --- Instance Methods ---
  # Fixture data: red_score=85.5, blue_score=72.3, red_win_probability=68.2, blue_win_probability=31.8

  test "winner returns red when red_win_probability > 50" do
    prediction = predictions(:prediction_qm1)
    assert_equal "red", prediction.winner
  end

  test "winner returns blue when blue_win_probability > 50" do
    prediction = predictions(:prediction_qm1)
    prediction.red_win_probability = 30.0
    prediction.blue_win_probability = 70.0
    assert_equal "blue", prediction.winner
  end

  test "winner returns tie when both at 50" do
    prediction = predictions(:prediction_qm1)
    prediction.red_win_probability = 50.0
    prediction.blue_win_probability = 50.0
    assert_equal "tie", prediction.winner
  end

  test "correct? returns nil when actual scores not set" do
    prediction = predictions(:prediction_qm1)
    # actual_red_score and actual_blue_score are nil in fixture
    assert_nil prediction.correct?
  end

  test "correct? returns true when predicted winner matches actual winner" do
    prediction = predictions(:prediction_qm1)
    # red_score=85.5 > blue_score=72.3, so predicted winner is red
    prediction.actual_red_score = 90
    prediction.actual_blue_score = 70
    assert prediction.correct?
  end

  test "correct? returns false when predicted winner differs from actual" do
    prediction = predictions(:prediction_qm1)
    # predicted winner is red (85.5 > 72.3)
    prediction.actual_red_score = 60
    prediction.actual_blue_score = 80
    assert_not prediction.correct?
  end

  test "margin_of_victory for prediction_qm1" do
    prediction = predictions(:prediction_qm1)
    # |85.5 - 72.3| = 13.2
    assert_equal 13.2, prediction.margin_of_victory
  end

  test "margin_of_victory when blue is higher" do
    prediction = predictions(:prediction_qm1)
    prediction.red_score = 60.0
    prediction.blue_score = 75.5
    # |60.0 - 75.5| = 15.5
    assert_equal 15.5, prediction.margin_of_victory
  end
end
