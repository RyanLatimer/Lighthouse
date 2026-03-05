# frozen_string_literal: true

require "test_helper"

class ReportBuilderServiceTest < ActiveSupport::TestCase
  setup do
    @report = reports(:team_summary_report)
    @service = ReportBuilderService.new(@report)
  end

  test "generate returns a hash with expected top-level keys" do
    result = @service.generate

    assert result.key?(:generated_at)
    assert result.key?(:event)
    assert result.key?(:metrics)
    assert result.key?(:chart_type)
    assert result.key?(:teams)
  end

  test "generate includes event information" do
    result = @service.generate
    event_data = result[:event]

    assert_equal events(:championship).id, event_data[:id]
    assert_equal "FIRST Championship", event_data[:name]
    assert_equal "2026cmp", event_data[:tba_key]
  end

  test "generate returns correct metrics from report config" do
    result = @service.generate

    assert_equal %w[avg_total_points fuel_accuracy_pct avg_climb_points], result[:metrics]
  end

  test "generate includes team rows with rank and metrics" do
    result = @service.generate
    teams = result[:teams]

    assert teams.size >= 1, "Should include at least one team"

    first = teams.first
    assert first.key?(:rank)
    assert first.key?(:team_number)
    assert first.key?(:nickname)
    assert first.key?(:team_id)
    assert first.key?("avg_total_points")
  end

  test "generate sorts teams by avg_total_points descending" do
    result = @service.generate
    teams = result[:teams]

    return if teams.size < 2

    scores = teams.map { |t| t["avg_total_points"] }
    assert_equal scores, scores.sort.reverse,
                 "Teams should be sorted by avg_total_points descending"
  end

  test "generate respects min_matches filter" do
    # The fixture report has min_matches: 1
    # Both team 254 and 1678 have 2 matches, so both should appear
    result = @service.generate

    team_numbers = result[:teams].map { |t| t[:team_number] }
    assert_includes team_numbers, 254
    assert_includes team_numbers, 1678
  end

  test "generate respects team filter" do
    # The fixture filter has teams: [254, 1678, 118, 4414] (team numbers)
    # But apply_filters uses frc_team.id (ActiveRecord IDs), so the filter
    # may not match if fixture IDs differ from team_numbers.
    # We create a report with specific team ID filtering.
    team_254 = frc_teams(:team_254)

    report = Report.create!(
      name: "Filtered Report",
      event: events(:championship),
      user: users(:admin_user),
      config: {
        "metrics" => [ "avg_total_points" ],
        "filters" => { "teams" => [ team_254.id ] },
        "sort_by" => "avg_total_points",
        "sort_dir" => "desc",
        "chart_type" => "table"
      }
    )

    service = ReportBuilderService.new(report)
    result = service.generate
    team_numbers = result[:teams].map { |t| t[:team_number] }

    assert_includes team_numbers, 254
    refute_includes team_numbers, 1678
  end

  test "generate with ascending sort" do
    report = Report.create!(
      name: "Ascending Report",
      event: events(:championship),
      user: users(:admin_user),
      config: {
        "metrics" => [ "avg_total_points" ],
        "filters" => {},
        "sort_by" => "avg_total_points",
        "sort_dir" => "asc",
        "chart_type" => "table"
      }
    )

    service = ReportBuilderService.new(report)
    result = service.generate
    teams = result[:teams]

    return if teams.size < 2

    scores = teams.map { |t| t["avg_total_points"] }
    assert_equal scores, scores.sort,
                 "Teams should be sorted by avg_total_points ascending"
  end

  test "generate chart_type comes from report config" do
    result = @service.generate
    assert_equal "table", result[:chart_type]
  end
end
