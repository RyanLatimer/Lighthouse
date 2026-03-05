# frozen_string_literal: true

class AggregationService
  include Scoring

  CONFIDENCE_THRESHOLDS = { low: 0...3, medium: 3...7 }.freeze
  CONFLICT_RELATIVE_THRESHOLD = 0.5 # 50% relative difference

  def initialize(event)
    @event = event
  end

  # Aggregates scouting data for a single team at this event.
  # Returns a hash with averages, accuracy, stddev, confidence, and raw reports.
  def aggregate_team(frc_team)
    entries = @event.scouting_entries
                    .where(frc_team: frc_team, status: 0)
                    .includes(:user, :match)
                    .order(:created_at)

    return empty_aggregation(frc_team) if entries.empty?

    scores = entries.map { |e| total_points_for(e) }
    fuel_made_values = entries.map { |e| fuel_made_for(e) }
    fuel_missed_values = entries.map { |e| fuel_missed_for(e) }
    climb_point_values = entries.map { |e| climb_points_for(e) }

    total_fuel = fuel_made_values.sum + fuel_missed_values.sum

    {
      frc_team: frc_team,
      avg_fuel_made: mean(fuel_made_values),
      avg_fuel_missed: mean(fuel_missed_values),
      fuel_accuracy_pct: total_fuel.positive? ? (fuel_made_values.sum.to_f / total_fuel * 100).round(1) : 0.0,
      avg_climb_points: mean(climb_point_values),
      avg_total_points: mean(scores),
      stddev_total_points: stddev(scores),
      matches_scouted: entries.size,
      confidence: confidence_level(entries.size),
      scouting_entries: entries
    }
  end

  # Aggregates all teams at this event, sorted by avg_total_points descending.
  def aggregate_all_teams
    team_ids = @event.scouting_entries.where(status: 0).select(:frc_team_id).distinct
    teams = FrcTeam.where(id: team_ids)

    teams.map { |team| aggregate_team(team) }
         .sort_by { |agg| -agg[:avg_total_points] }
  end

  # Refreshes the TeamEventSummary materialized view.
  def refresh_materialized_view!
    TeamEventSummary.refresh!
  end

  # Detects conflicts across scouts for the same team+match.
  # Returns an array of newly created DataConflict records.
  def detect_conflicts!
    new_conflicts = []

    # Group scouting entries by (frc_team, match) pairs
    grouped = @event.scouting_entries
                    .where(status: 0)
                    .where.not(match_id: nil)
                    .includes(:user)
                    .group_by { |e| [ e.frc_team_id, e.match_id ] }

    grouped.each do |(frc_team_id, match_id), entries|
      next if entries.size < 2

      # Collect all data keys across entries
      all_keys = entries.flat_map { |e| e.data.keys }.uniq

      all_keys.each do |key|
        values_by_scout = entries.each_with_object({}) do |entry, hash|
          hash[entry.user_id] = entry.data[key]
        end

        # Skip if all scouts agree or only one scout reported this field
        reported = values_by_scout.compact
        next if reported.size < 2
        next unless conflict?(reported.values)

        conflict = DataConflict.find_or_initialize_by(
          event_id: @event.id,
          frc_team_id: frc_team_id,
          match_id: match_id,
          field_name: key
        )

        conflict.values = values_by_scout
        conflict.resolved = false if conflict.new_record?

        if conflict.new_record? || conflict.changed?
          conflict.save!
          new_conflicts << conflict
        end
      end
    end

    new_conflicts
  end

  private

  def fuel_made_for(entry)
    d = entry.data
    (d["auton_fuel_made"].to_f + d["teleop_fuel_made"].to_f + d["endgame_fuel_made"].to_f)
  end

  def fuel_missed_for(entry)
    d = entry.data
    (d["auton_fuel_missed"].to_f + d["teleop_fuel_missed"].to_f + d["endgame_fuel_missed"].to_f)
  end

  def climb_points_for(entry)
    d = entry.data
    auton = d["auton_climb"].to_s == "true" ? AUTON_CLIMB_POINTS : 0
    endgame = CLIMB_POINTS.fetch(d["endgame_climb"].to_s, 0)
    auton + endgame
  end

  def total_points_for(entry)
    fuel_made_for(entry) * FUEL_POINT_VALUE + climb_points_for(entry)
  end

  def mean(values)
    return 0.0 if values.empty?
    (values.sum.to_f / values.size).round(2)
  end

  def stddev(values)
    return 0.0 if values.size < 2
    avg = values.sum.to_f / values.size
    variance = values.sum { |v| (v - avg)**2 } / (values.size - 1)
    Math.sqrt(variance).round(2)
  end

  def confidence_level(count)
    if CONFIDENCE_THRESHOLDS[:low].cover?(count)
      "low"
    elsif CONFIDENCE_THRESHOLDS[:medium].cover?(count)
      "medium"
    else
      "high"
    end
  end

  def conflict?(values)
    # Check if all values are numeric-like
    numeric = values.all? { |v| v.to_s.match?(/\A-?\d+(\.\d+)?\z/) }

    if numeric
      nums = values.map(&:to_f)
      max_val = nums.max.abs
      min_val = nums.min.abs
      avg = (max_val + min_val) / 2.0
      return false if avg.zero?

      (nums.max - nums.min).abs / avg > CONFLICT_RELATIVE_THRESHOLD
    else
      values.uniq.size > 1
    end
  end

  def empty_aggregation(frc_team)
    {
      frc_team: frc_team,
      avg_fuel_made: 0.0,
      avg_fuel_missed: 0.0,
      fuel_accuracy_pct: 0.0,
      avg_climb_points: 0.0,
      avg_total_points: 0.0,
      stddev_total_points: 0.0,
      matches_scouted: 0,
      confidence: "low",
      scouting_entries: ScoutingEntry.none
    }
  end
end
