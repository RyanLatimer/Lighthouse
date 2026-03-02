class TeamsController < ApplicationController
  before_action :require_event!

  def index
    @teams = policy_scope(FrcTeam)
               .at_event(current_event)
               .order(:team_number)

    @summaries = TeamEventSummary.where(event: current_event).index_by(&:frc_team_id)
  end

  def show
    @team = FrcTeam.find(params[:id])
    authorize @team, policy_class: FrcTeamPolicy

    @entries = ScoutingEntry.where(event: current_event, frc_team: @team)
                            .includes(:match, :user)
                            .order(created_at: :desc)

    @summary = TeamEventSummary.find_by(event: current_event, frc_team: @team)
    @matches = @team.matches.where(event: current_event).ordered
    @pit_entry = PitScoutingEntry.find_by(event: current_event, frc_team: @team)
  end
end
