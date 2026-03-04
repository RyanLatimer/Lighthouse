class PitScoutingEntriesController < ApplicationController
  include SyncCsrfProtection

  before_action :require_event!, except: :sync
  skip_forgery_protection only: :sync
  before_action :verify_sync_origin, only: :sync
  before_action :set_pit_scouting_entry, only: %i[show edit update destroy]

  def index
    @pit_scouting_entries = policy_scope(PitScoutingEntry)
                              .where(event: current_event)
                              .includes(:user, :frc_team)
                              .order(updated_at: :desc)

    @teams = FrcTeam.at_event(current_event).order(:team_number)
    @scouted_team_ids = @pit_scouting_entries.pluck(:frc_team_id).uniq
  end

  def show
    authorize @pit_scouting_entry
  end

  def new
    @pit_scouting_entry = PitScoutingEntry.new(event: current_event)
    authorize @pit_scouting_entry
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def create
    @pit_scouting_entry = current_user.pit_scouting_entries.build(pit_scouting_entry_params)
    @pit_scouting_entry.event = current_event
    @pit_scouting_entry.organization = current_organization
    authorize @pit_scouting_entry

    if @pit_scouting_entry.client_uuid.present?
      existing = PitScoutingEntry.find_by(client_uuid: @pit_scouting_entry.client_uuid)
      if existing
        redirect_to existing, notice: "Entry already synced."
        return
      end
    end

    if @pit_scouting_entry.save
      redirect_to @pit_scouting_entry, notice: "Pit scouting entry created."
    else
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pit_scouting_entry
    @teams = FrcTeam.at_event(current_event).order(:team_number)
  end

  def update
    authorize @pit_scouting_entry

    if @pit_scouting_entry.update(pit_scouting_entry_params)
      redirect_to @pit_scouting_entry, notice: "Pit scouting entry updated."
    else
      @teams = FrcTeam.at_event(current_event).order(:team_number)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pit_scouting_entry
    @pit_scouting_entry.destroy!
    redirect_to pit_scouting_entries_path, notice: "Pit scouting entry deleted.", status: :see_other
  end

  # POST /pit_scouting_entries/sync — offline sync endpoint
  def sync
    authorize :pit_scouting_entry, :sync?

    entries_params = params.require(:entries)
    results = []
    created_event_ids = []

    entries_params.each do |entry_data|
      entry = PitScoutingEntry.find_by(client_uuid: entry_data[:client_uuid])

      if entry
        results << { client_uuid: entry_data[:client_uuid], status: "existing", id: entry.id }
      else
        # organization_id is forced from the session — not caller-controlled
        permitted = entry_data.permit(:frc_team_id, :event_id, :notes, :client_uuid, :status, data: {})
                              .merge(user_id: current_user.id, organization_id: current_organization&.id)

        # Validate the caller-supplied event_id references a real event
        # and belongs to the user's current organization
        sync_event = Event.find_by(id: permitted[:event_id])
        unless sync_event && (sync_event.organization_id.nil? || sync_event.organization_id == current_organization&.id)
          results << { client_uuid: entry_data[:client_uuid], status: "error", errors: [ "Invalid event" ] }
          next
        end

        entry = PitScoutingEntry.from_offline_data(permitted)

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

  def set_pit_scouting_entry
    @pit_scouting_entry = PitScoutingEntry.find(params[:id])
  end

  def pit_scouting_entry_params
    params.require(:pit_scouting_entry).permit(
      :frc_team_id, :notes, :client_uuid, :status,
      data: {},
      photos: []
    )
  end
end
