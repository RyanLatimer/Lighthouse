# frozen_string_literal: true

class SimulationResult < ApplicationRecord
  belongs_to :user
  belongs_to :event

  validates :red_team_ids, presence: true
  validates :blue_team_ids, presence: true

  def red_teams
    FrcTeam.where(id: red_team_ids)
  end

  def blue_teams
    FrcTeam.where(id: blue_team_ids)
  end

  def red_avg
    results&.dig("red_avg").to_f
  end

  def blue_avg
    results&.dig("blue_avg").to_f
  end

  def red_win_pct
    results&.dig("red_win_pct").to_f
  end

  def blue_win_pct
    results&.dig("blue_win_pct").to_f
  end

  def margin_of_victory
    results&.dig("margin_of_victory").to_f
  end
end
