# frozen_string_literal: true

class Report < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :name, presence: true

  # Config structure example:
  # {
  #   metrics: ["avg_total_points", "fuel_accuracy_pct", "avg_climb_points"],
  #   filters: { teams: [1, 2, 3], min_matches: 3 },
  #   group_by: "team", # or "match", "phase"
  #   sort_by: "avg_total_points",
  #   sort_dir: "desc",
  #   chart_type: "table" # or "bar", "line", "radar", "scatter"
  # }

  def metrics
    config&.dig("metrics") || []
  end

  def filters
    config&.dig("filters") || {}
  end

  def chart_type
    config&.dig("chart_type") || "table"
  end

  def sort_by
    config&.dig("sort_by") || "avg_total_points"
  end

  def sort_dir
    config&.dig("sort_dir") || "desc"
  end
end
