class DashboardController < ApplicationController
  skip_after_action :pundit_verify

  def index
    authorize :dashboard, :index?

    if current_event
      @event = current_event
      @team_summaries = TeamEventSummary.where(event: @event).order(avg_total_points: :desc)
      @recent_entries = ScoutingEntry.where(event: @event).order(created_at: :desc).limit(10)
      @unresolved_conflicts_count = DataConflict.where(event: @event).unresolved.count

      # Pit scouting progress
      @total_teams_at_event = FrcTeam.at_event(@event).count
      @pit_scouted_count = PitScoutingEntry.where(event: @event).distinct.count(:frc_team_id)

      # Scout activity (last 7 days)
      @scout_activity = ScoutingEntry.where(event: @event)
                                     .where("created_at >= ?", 7.days.ago)
                                     .group(:user_id)
                                     .count
      @top_scouts = User.where(id: @scout_activity.keys)
                        .index_by(&:id)

      # Scoring distribution for histogram (total points per entry)
      @scoring_data = @team_summaries.pluck(:avg_total_points).map { |v| v.to_f.round(0) }

      # Predictions summary
      @predictions_count = Prediction.where(event: @event).count
    else
      @events = Event.current_year.order(start_date: :asc)
    end
  end
end
