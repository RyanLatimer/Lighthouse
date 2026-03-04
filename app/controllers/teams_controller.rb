class TeamsController < ApplicationController
  before_action :require_event!

  def index
    @teams = policy_scope(FrcTeam)
               .at_event(current_event)
               .order(:team_number)

    @summaries = TeamEventSummary.where(event: current_event).index_by(&:frc_team_id)

    # Load Statbotics EPA — try bulk sync if cache is empty
    ensure_statbotics_cached!
    @statbotics_epa = StatboticsCache.where(event: current_event)
                                     .index_by(&:frc_team_id)

    # Fetch event rankings from TBA (cached 5 min)
    @rankings = fetch_tba_rankings
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

    # Single DB query — no external API call
    @epa = StatboticsCache.find_by(event: current_event, frc_team: @team)
  end

  private

  def ensure_statbotics_cached!
    return if StatboticsCache.where(event: current_event).exists?
    return unless current_event.tba_key.present?

    SyncStatboticsJob.perform_now(current_event.id)
  rescue StandardError => e
    Rails.logger.warn("[TeamsController] Statbotics sync failed: #{e.message}")
  end

  # Returns a hash of team_number => rank from TBA, or empty hash on failure.
  def fetch_tba_rankings
    return {} unless current_event.tba_key.present?

    data = TbaClient.new.event_rankings(current_event.tba_key)
    return {} unless data.is_a?(Hash) && data["rankings"].is_a?(Array)

    data["rankings"].each_with_object({}) do |entry, hash|
      # TBA team_key is "frc254", extract the number
      team_number = entry["team_key"].to_s.delete_prefix("frc").to_i
      rp_avg = entry.dig("sort_orders", 0)&.to_f
      hash[team_number] = { rank: entry["rank"], rp_avg: rp_avg }
    end
  rescue StandardError => e
    Rails.logger.warn("[TeamsController] TBA rankings fetch failed: #{e.message}")
    {}
  end
end
