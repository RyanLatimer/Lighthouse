class QrImportsController < ApplicationController
  skip_forgery_protection only: :import
  before_action :verify_sync_origin, only: :import

  # GET /qr_imports/scanner
  def scanner
    authorize :qr_import, :scanner?
  end

  # POST /qr_imports/import
  # Accepts a single scouting entry decoded from a QR code.
  # Uses Last-Write-Wins (LWW) conflict resolution when a client_uuid already exists.
  def import
    authorize :qr_import, :import?

    entry_params = params.require(:entry).permit(
      :client_uuid, :match_id, :frc_team_id, :event_id,
      :notes, :status, :updated_at,
      data: {}
    )

    # Validate required fields
    unless entry_params[:client_uuid].present? && entry_params[:event_id].present? && entry_params[:frc_team_id].present?
      render json: { status: "error", errors: [ "Missing required fields (client_uuid, event_id, frc_team_id)" ] }, status: :unprocessable_entity
      return
    end

    # Validate the event exists
    event = Event.find_by(id: entry_params[:event_id])
    unless event
      render json: { status: "error", errors: [ "Invalid event" ] }, status: :unprocessable_entity
      return
    end

    existing = ScoutingEntry.find_by(client_uuid: entry_params[:client_uuid])

    if existing
      # LWW conflict resolution: compare timestamps
      incoming_time = Time.parse(entry_params[:updated_at]) rescue existing.updated_at
      server_time = existing.updated_at

      if incoming_time > server_time
        # Incoming is newer — update the existing record
        existing.update!(
          data:   entry_params[:data] || {},
          notes:  entry_params[:notes],
          status: entry_params[:status] || :submitted
        )
        RefreshSummariesJob.perform_later(existing.event_id)

        render json: {
          status: "updated",
          id: existing.id,
          team_number: existing.frc_team.team_number,
          match_name: existing.match&.display_name || "N/A"
        }
      else
        # Server copy is same age or newer — skip
        render json: {
          status: "existing",
          id: existing.id,
          team_number: existing.frc_team.team_number,
          match_name: existing.match&.display_name || "N/A"
        }
      end
    else
      # New entry — create it, attributed to the current user (the importer)
      entry = ScoutingEntry.new(
        user:        current_user,
        match_id:    entry_params[:match_id],
        frc_team_id: entry_params[:frc_team_id],
        event_id:    entry_params[:event_id],
        data:        entry_params[:data] || {},
        notes:       entry_params[:notes],
        client_uuid: entry_params[:client_uuid],
        status:      entry_params[:status] || :submitted
      )

      if entry.save
        RefreshSummariesJob.perform_later(entry.event_id)

        render json: {
          status: "created",
          id: entry.id,
          team_number: entry.frc_team.team_number,
          match_name: entry.match&.display_name || "N/A"
        }
      else
        render json: {
          status: "error",
          errors: entry.errors.full_messages
        }, status: :unprocessable_entity
      end
    end
  rescue StandardError => e
    Rails.logger.error("QR import failed: #{e.message}")
    render json: { status: "error", errors: [ e.message ] }, status: :unprocessable_entity
  end

  private

  # Reuse the sync CSRF protection concern
  include SyncCsrfProtection
end
