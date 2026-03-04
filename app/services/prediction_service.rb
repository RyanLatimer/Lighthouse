# frozen_string_literal: true

class PredictionService
  # Minimum scouting entries per team for full scouting weight
  MIN_ENTRIES_FOR_FULL_WEIGHT = 6

  def initialize(event)
    @event = event
    @aggregation = AggregationService.new(event)
    @statbotics = StatboticsClient.new
    @simulator = MatchSimulatorService.new(event, statbotics: @statbotics)
    @statbotics_matches_cache = nil
  end

  # Generate predictions for all matches at the event
  def generate_all!
    # Pre-fetch all Statbotics match data once for the entire event
    warm_statbotics_cache!

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

    # Get Statbotics EPA match prediction if available
    statbotics_data = fetch_statbotics_predictions(match)

    # Determine blending weights based on scouting data quality
    scouting_weight, statbotics_weight = compute_weights(red_teams + blue_teams, statbotics_data)

    # Blend the predictions
    if statbotics_data && statbotics_weight > 0
      red_score = sim_result[:red_avg] * scouting_weight + statbotics_data[:red_score] * statbotics_weight
      blue_score = sim_result[:blue_avg] * scouting_weight + statbotics_data[:blue_score] * statbotics_weight
      red_win_pct = sim_result[:red_win_pct] * scouting_weight + statbotics_data[:red_win_pct] * statbotics_weight
      blue_win_pct = sim_result[:blue_win_pct] * scouting_weight + statbotics_data[:blue_win_pct] * statbotics_weight
    else
      red_score = sim_result[:red_avg]
      blue_score = sim_result[:blue_avg]
      red_win_pct = sim_result[:red_win_pct]
      blue_win_pct = sim_result[:blue_win_pct]
    end

    prediction = Prediction.find_or_initialize_by(
      match: match,
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
        weights: { scouting: scouting_weight.round(2), statbotics: statbotics_weight.round(2) },
        red_teams: red_teams.map(&:team_number),
        blue_teams: blue_teams.map(&:team_number)
      }
    )

    # Back-fill actual scores from Statbotics results if available
    backfill_actual_scores!(prediction, match)

    prediction.save!
    prediction
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("[PredictionService] Failed to save prediction for match #{match.id}: #{e.message}")
    nil
  end

  private

  # Pre-fetches and indexes Statbotics match data for the event
  def warm_statbotics_cache!
    return unless @event.tba_key.present?

    matches_data = @statbotics.matches(@event.tba_key)
    if matches_data.is_a?(Array)
      @statbotics_matches_cache = matches_data.index_by { |m| m["key"] }
    end
  rescue StandardError => e
    Rails.logger.warn("[PredictionService] Failed to warm Statbotics cache: #{e.message}")
  end

  # Computes adaptive blending weights based on scouting data availability.
  # With no scouting data: 100% Statbotics.
  # With full scouting data (>= MIN_ENTRIES_FOR_FULL_WEIGHT per team): 50/50.
  def compute_weights(teams, statbotics_data)
    entry_counts = teams.map do |team|
      @event.scouting_entries.where(frc_team: team, status: 0).count
    end

    avg_entries = entry_counts.sum.to_f / [ entry_counts.size, 1 ].max
    scouting_coverage = [ avg_entries / MIN_ENTRIES_FOR_FULL_WEIGHT, 1.0 ].min

    if statbotics_data
      # Scale scouting weight from 0.0 (no data) to 0.5 (full data)
      scouting_weight = scouting_coverage * 0.5
      statbotics_weight = 1.0 - scouting_weight
    else
      scouting_weight = 1.0
      statbotics_weight = 0.0
    end

    [ scouting_weight, statbotics_weight ]
  end

  def fetch_statbotics_predictions(match)
    return nil unless @event.tba_key.present?

    # Use pre-warmed cache if available, otherwise fetch fresh
    match_data = if @statbotics_matches_cache
      @statbotics_matches_cache[match.tba_key]
    else
      matches_data = @statbotics.matches(@event.tba_key)
      return nil unless matches_data.is_a?(Array)
      matches_data.find { |m| m["key"] == match.tba_key }
    end

    return nil unless match_data

    pred = match_data["pred"]
    return nil unless pred

    red_win_prob = pred["red_win_prob"].to_f
    {
      red_score: pred["red_score"].to_f,
      blue_score: pred["blue_score"].to_f,
      red_win_pct: (red_win_prob * 100).round(1),
      blue_win_pct: ((1.0 - red_win_prob) * 100).round(1)
    }
  rescue StandardError => e
    Rails.logger.warn("[PredictionService] Statbotics fetch failed: #{e.message}")
    nil
  end

  # Back-fills actual match scores from Statbotics result data
  def backfill_actual_scores!(prediction, match)
    return if prediction.actual_red_score.present?
    return unless @event.tba_key.present?

    match_data = if @statbotics_matches_cache
      @statbotics_matches_cache[match.tba_key]
    else
      nil
    end

    return unless match_data

    result = match_data["result"]
    return unless result && result["red_score"].present?

    prediction.actual_red_score = result["red_score"].to_i
    prediction.actual_blue_score = result["blue_score"].to_i
  end
end
