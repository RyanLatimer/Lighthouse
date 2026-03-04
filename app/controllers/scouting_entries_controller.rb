class ScoutingEntriesController < ApplicationController
  include SyncCsrfProtection

  before_action :require_event!, except: :sync
  skip_forgery_protection only: :sync
  before_action :verify_sync_origin, only: :sync
  before_action :set_scouting_entry, only: %i[show edit update destroy]

  def index
    @scouting_entries = policy_scope(ScoutingEntry)
                          .where(event: current_event)
                          .includes(:user, :frc_team, :match)
                          .order(created_at: :desc)
  end

  def show
    authorize @scouting_entry
  end

  def new
    @scouting_entry = ScoutingEntry.new(event: current_event)
    authorize @scouting_entry

    @game_config = GameConfig.current
    @matches = current_event.matches.includes(match_alliances: :frc_team).ordered
    @teams = FrcTeam.at_event(current_event).order(:team_number)
    @match_teams = build_match_teams_map(@matches)
  end

  def create
    @scouting_entry = current_user.scouting_entries.build(scouting_entry_params)
    @scouting_entry.event = current_event
    authorize @scouting_entry

    # Handle offline sync: skip if a duplicate client_uuid already exists
    if @scouting_entry.client_uuid.present?
      existing = ScoutingEntry.find_by(client_uuid: @scouting_entry.client_uuid)
      if existing
        redirect_to existing, notice: "Entry already synced."
        return
      end
    end

    if @scouting_entry.save
      @scouting_entry.broadcast_prepend_to(
        "scouting_entries_event_#{current_event.id}",
        target: "scouting_entries",
        partial: "scouting_entries/scouting_entry",
        locals: { scouting_entry: @scouting_entry }
      )
      RefreshSummariesJob.perform_later(current_event.id)
      redirect_to @scouting_entry, notice: "Scouting entry was successfully created."
    else
      @game_config = GameConfig.current
      @matches = current_event.matches.includes(match_alliances: :frc_team).ordered
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      @match_teams = build_match_teams_map(@matches)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @scouting_entry
    @game_config = GameConfig.current
    @matches = current_event.matches.includes(match_alliances: :frc_team).ordered
    @teams = FrcTeam.at_event(current_event).order(:team_number)
    @match_teams = build_match_teams_map(@matches)
  end

  def update
    authorize @scouting_entry

    if @scouting_entry.update(scouting_entry_params)
      RefreshSummariesJob.perform_later(current_event.id)
      redirect_to @scouting_entry, notice: "Scouting entry was successfully updated."
    else
      @game_config = GameConfig.current
      @matches = current_event.matches.includes(match_alliances: :frc_team).ordered
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      @match_teams = build_match_teams_map(@matches)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scouting_entry
    event_id = @scouting_entry.event_id
    @scouting_entry.destroy!
    RefreshSummariesJob.perform_later(event_id)
    redirect_to scouting_entries_path, notice: "Scouting entry was successfully deleted.", status: :see_other
  end

  # POST /scouting_entries/sync — offline sync endpoint
  def sync
    authorize :scouting_entry, :sync?

    entries_params = params.require(:entries)
    results = []
    created_event_ids = []

    entries_params.each do |entry_data|
      entry = ScoutingEntry.find_by(client_uuid: entry_data[:client_uuid])

      if entry
        results << { client_uuid: entry_data[:client_uuid], status: "existing", id: entry.id }
      else
        # organization_id is forced from the session — not caller-controlled
        permitted = entry_data.permit(:match_id, :frc_team_id, :event_id, :notes, :photo_url, :client_uuid, :status, data: {})
                              .merge(user_id: current_user.id, organization_id: current_organization&.id)

        # Validate the caller-supplied event_id references a real event
        # and belongs to the user's current organization
        sync_event = Event.find_by(id: permitted[:event_id])
        unless sync_event && (sync_event.organization_id.nil? || sync_event.organization_id == current_organization&.id)
          results << { client_uuid: entry_data[:client_uuid], status: "error", errors: [ "Invalid event" ] }
          next
        end

        entry = ScoutingEntry.from_offline_data(permitted)

        if entry.save
          results << { client_uuid: entry_data[:client_uuid], status: "created", id: entry.id }
          created_event_ids << permitted[:event_id].to_i if permitted[:event_id].present?
        else
          results << { client_uuid: entry_data[:client_uuid], status: "error", errors: entry.errors.full_messages }
        end
      end
    end

    # Refresh summaries for the events that actually received new entries
    created_event_ids.uniq.each { |eid| RefreshSummariesJob.perform_later(eid) }

    render json: { results: results }
  end

  private

  def set_scouting_entry
    @scouting_entry = ScoutingEntry.find(params[:id])
  end

  def scouting_entry_params
    permitted = params.require(:scouting_entry).permit(
      :match_id, :frc_team_id, :notes, :photo_url, :client_uuid, :status,
      data: {}
    )

    # The scouting form JS packs all scoring data into data[_json] as a JSON string.
    # Parse it and replace the raw data hash so the JSONB column gets real values.
    if permitted[:data].is_a?(ActionController::Parameters) && permitted[:data][:_json].present?
      permitted[:data] = JSON.parse(permitted[:data][:_json])
    end

    permitted
  end

  # Returns a Hash mapping match_id to an array of team info for the team dropdown.
  # { match.id => [ { id: frc_team.id, number: 254, name: "The Cheesy Poofs", color: "red" }, ... ] }
  def build_match_teams_map(matches)
    matches.each_with_object({}) do |match, map|
      map[match.id] = match.match_alliances
        .sort_by { |ma| [ ma.alliance_color, ma.station ] }
        .map do |ma|
          {
            id: ma.frc_team.id,
            number: ma.frc_team.team_number,
            name: ma.frc_team.nickname,
            color: ma.alliance_color
          }
        end
    end
  end
end
