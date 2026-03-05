module Api
  module V1
    class PitScoutingEntriesController < ActionController::API
      include ApiAuthenticatable

      def create
        entry = PitScoutingEntry.from_offline_data(
          entry_params.merge(user_id: current_api_user.id)
        )

        if entry.client_uuid.present?
          existing = PitScoutingEntry.find_by(client_uuid: entry.client_uuid)
          if existing
            render json: { status: "existing", id: existing.id, client_uuid: existing.client_uuid }, status: :ok
            return
          end
        end

        if entry.save
          render json: { status: "created", id: entry.id, client_uuid: entry.client_uuid }, status: :created
        else
          render json: { status: "error", errors: entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def bulk_sync
        entries_data = params.require(:entries)
        results = []

        entries_data.each do |entry_data|
          permitted = entry_data.permit(
            :event_id, :frc_team_id,
            :notes, :client_uuid, :status,
            data: {}
          ).merge(user_id: current_api_user.id)

          existing = PitScoutingEntry.find_by(client_uuid: permitted[:client_uuid]) if permitted[:client_uuid].present?

          if existing
            results << { client_uuid: permitted[:client_uuid], status: "existing", id: existing.id }
          else
            entry = PitScoutingEntry.from_offline_data(permitted)
            if entry.save
              results << { client_uuid: permitted[:client_uuid], status: "created", id: entry.id }
            else
              results << { client_uuid: permitted[:client_uuid], status: "error", errors: entry.errors.full_messages }
            end
          end
        end

        render json: { results: results }
      end

      private

      def entry_params
        params.require(:pit_scouting_entry).permit(
          :event_id, :frc_team_id,
          :notes, :client_uuid, :status,
          data: {}
        )
      end
    end
  end
end
