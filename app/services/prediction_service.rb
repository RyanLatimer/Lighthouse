# frozen_string_literal: true

class PredictionService
  SCOUTING_WEIGHT = 0.5
  STATBOTICS_WEIGHT = 0.5

  def initialize(event, organization = nil)
    @event = event
    @organization = organization
    @aggregation = AggregationService.new(event)
    @statbotics = StatboticsClient.new
    @simulator = MatchSimulatorService.new(event)
  end

  # Generate predictions for all matches at the event
  def generate_all!
    matches = @event.matches.includes(match_alliances: :frc_team)
    count = 0

    matches.find_each do |match|
      red_teams = match.match_alliances.select { |ma| ma.alliance_color == "red" }.sort_by(&:station).map(&:frc_team)
      blue_teams = match.match_alliances.select { |ma| ma.alliance_color == "blue" }.sort_by(&:station).map(&:frc_team)

      next if red_teams.empty? || blue_teams.empty?

      prediction = predict_match(match, red_teams, blue_teams)
      next unless prediction

      count += 1
    end

    count
  end

  # Generate a prediction for a single match
  def predict_match(match, red_teams, blue_teams)
    # Get scouting-based prediction via Monte Carlo
    sim_result = @simulator.simulate(red_teams, blue_teams)

    # Get Statbotics EPA data if available
    statbotics_data = fetch_statbotics_predictions(match)

    # Blend the predictions
    if statbotics_data
      red_score = sim_result[:red_avg] * SCOUTING_WEIGHT + statbotics_data[:red_score] * STATBOTICS_WEIGHT
      blue_score = sim_result[:blue_avg] * SCOUTING_WEIGHT + statbotics_data[:blue_score] * STATBOTICS_WEIGHT
      red_win_pct = sim_result[:red_win_pct] * SCOUTING_WEIGHT + statbotics_data[:red_win_pct] * STATBOTICS_WEIGHT
      blue_win_pct = sim_result[:blue_win_pct] * SCOUTING_WEIGHT + statbotics_data[:blue_win_pct] * STATBOTICS_WEIGHT
    else
      red_score = sim_result[:red_avg]
      blue_score = sim_result[:blue_avg]
      red_win_pct = sim_result[:red_win_pct]
      blue_win_pct = sim_result[:blue_win_pct]
    end

    prediction = Prediction.find_or_initialize_by(
      match: match,
      organization: @organization,
      source: "blended"
    )

    prediction.assign_attributes(
      event: @event,
      red_score: red_score.round(1),
      blue_score: blue_score.round(1),
      red_win_probability: red_win_pct.round(1),
      blue_win_probability: blue_win_pct.round(1),
      details: {
        scouting: sim_result,
        statbotics: statbotics_data,
        weights: { scouting: SCOUTING_WEIGHT, statbotics: STATBOTICS_WEIGHT },
        red_teams: red_teams.map(&:team_number),
        blue_teams: blue_teams.map(&:team_number)
      }
    )

    prediction.save!
    prediction
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[PredictionService] Failed to save prediction for match #{match.id}: #{e.message}")
    nil
  end

  private

  def fetch_statbotics_predictions(match)
    return nil unless @event.tba_key.present?

    matches_data = @statbotics.matches(@event.tba_key)
    return nil unless matches_data.is_a?(Array)

    match_data = matches_data.find { |m| m["key"] == match.tba_key }
    return nil unless match_data

    pred = match_data["pred"]
    return nil unless pred

    {
      red_score: pred["red_score"].to_f,
      blue_score: pred["blue_score"].to_f,
      red_win_pct: (pred["red_win_prob"].to_f * 100).round(1),
      blue_win_pct: (pred["blue_win_prob"].to_f * 100).round(1)
    }
  rescue StandardError => e
    Rails.logger.warn("[PredictionService] Statbotics fetch failed: #{e.message}")
    nil
  end
end
