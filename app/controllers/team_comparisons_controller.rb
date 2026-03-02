class TeamComparisonsController < ApplicationController
  before_action :require_event!
  skip_after_action :pundit_verify

  def show
    authorize :team_comparison, :show?

    team_ids = (params[:teams] || "").split(",").map(&:to_i).reject(&:zero?)
    @teams = FrcTeam.where(id: team_ids).order(:team_number)
    @all_teams = FrcTeam.at_event(current_event).order(:team_number)

    @summaries = {}
    @entries_by_team = {}
    @pit_data = {}

    @teams.each do |team|
      @summaries[team.id] = TeamEventSummary.find_by(event: current_event, frc_team: team)
      @entries_by_team[team.id] = ScoutingEntry.where(event: current_event, frc_team: team)
                                               .includes(:match)
                                               .order(created_at: :asc)
      @pit_data[team.id] = PitScoutingEntry.find_by(event: current_event, frc_team: team)
    end
  end
end
