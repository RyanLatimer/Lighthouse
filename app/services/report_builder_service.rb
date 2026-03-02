# frozen_string_literal: true

class ReportBuilderService
  AVAILABLE_METRICS = %w[
    avg_total_points avg_fuel_made avg_fuel_missed fuel_accuracy_pct
    avg_climb_points stddev_total_points matches_scouted
    avg_auto_points avg_teleop_points climb_success_rate
  ].freeze

  def initialize(report)
    @report = report
    @event = report.event
    @aggregation = AggregationService.new(@event)
  end

  def generate
    aggregations = @aggregation.aggregate_all_teams

    # Apply filters
    aggregations = apply_filters(aggregations)

    # Sort
    sort_field = @report.sort_by
    aggregations = aggregations.sort_by { |agg| -(agg[sort_field.to_sym] || 0) }
    aggregations.reverse! if @report.sort_dir == "asc"

    # Build report data
    {
      generated_at: Time.current.iso8601,
      event: { id: @event.id, name: @event.name, tba_key: @event.tba_key },
      metrics: @report.metrics,
      chart_type: @report.chart_type,
      teams: aggregations.map.with_index do |agg, idx|
        team = agg[:frc_team]
        row = {
          rank: idx + 1,
          team_number: team.team_number,
          nickname: team.nickname,
          team_id: team.id
        }

        @report.metrics.each do |metric|
          row[metric] = agg[metric.to_sym]
        end

        row
      end
    }
  end

  private

  def apply_filters(aggregations)
    filters = @report.filters

    if filters["teams"].present?
      team_ids = filters["teams"].map(&:to_i)
      aggregations = aggregations.select { |agg| team_ids.include?(agg[:frc_team].id) }
    end

    if filters["min_matches"].present?
      min = filters["min_matches"].to_i
      aggregations = aggregations.select { |agg| agg[:matches_scouted] >= min }
    end

    aggregations
  end
end
