class PitScoutingEntriesController < ApplicationController
  before_action :require_event!
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
