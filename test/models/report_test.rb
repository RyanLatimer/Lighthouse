require "test_helper"

class ReportTest < ActiveSupport::TestCase
  # --- Validations ---

  test "valid report from fixtures" do
    assert reports(:team_summary_report).valid?
  end

  test "requires name" do
    report = reports(:team_summary_report)
    report.name = nil
    assert_not report.valid?
    assert_includes report.errors[:name], "can't be blank"
  end

  # --- Associations ---

  test "belongs to user" do
    assert_equal users(:admin_user), reports(:team_summary_report).user
  end

  test "belongs to event" do
    assert_equal events(:championship), reports(:team_summary_report).event
  end

  # --- Computed Methods ---
  # Fixture config: metrics=["avg_total_points","fuel_accuracy_pct","avg_climb_points"],
  #   filters={teams:[254,1678,118,4414], min_matches:1}, group_by="team",
  #   sort_by="avg_total_points", sort_dir="desc", chart_type="table"

  test "metrics returns array from config" do
    report = reports(:team_summary_report)
    assert_equal [ "avg_total_points", "fuel_accuracy_pct", "avg_climb_points" ], report.metrics
  end

  test "filters returns hash from config" do
    report = reports(:team_summary_report)
    filters = report.filters
    assert_kind_of Hash, filters
    assert_equal 1, filters["min_matches"]
  end

  test "chart_type returns table from config" do
    report = reports(:team_summary_report)
    assert_equal "table", report.chart_type
  end

  test "sort_by returns avg_total_points from config" do
    report = reports(:team_summary_report)
    assert_equal "avg_total_points", report.sort_by
  end

  test "sort_dir returns desc from config" do
    report = reports(:team_summary_report)
    assert_equal "desc", report.sort_dir
  end

  # --- Edge cases ---

  test "metrics returns empty array when config is nil" do
    report = Report.new(name: "Empty", event: events(:championship), user: users(:admin_user))
    assert_equal [], report.metrics
  end

  test "filters returns empty hash when config is nil" do
    report = Report.new(name: "Empty", event: events(:championship), user: users(:admin_user))
    assert_equal({}, report.filters)
  end

  test "chart_type defaults to table when not in config" do
    report = Report.new(name: "Empty", config: {}, event: events(:championship), user: users(:admin_user))
    assert_equal "table", report.chart_type
  end

  test "sort_by defaults to avg_total_points when not in config" do
    report = Report.new(name: "Empty", config: {}, event: events(:championship), user: users(:admin_user))
    assert_equal "avg_total_points", report.sort_by
  end

  test "sort_dir defaults to desc when not in config" do
    report = Report.new(name: "Empty", config: {}, event: events(:championship), user: users(:admin_user))
    assert_equal "desc", report.sort_dir
  end
end
