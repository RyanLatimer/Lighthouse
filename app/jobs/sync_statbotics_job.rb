# frozen_string_literal: true

class SyncStatboticsJob < ApplicationJob
  queue_as :default
  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  # Fetches latest EPA and prediction data from Statbotics for an event.
  # This warms the Rails cache so PredictionService reads are fast.
  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event&.tba_key.present?

    client = StatboticsClient.new

    # Warm event-level cache
    client.event(event.tba_key)

    # Warm match predictions cache
    client.matches(event.tba_key)

    # Warm per-team EPA cache for current year
    event.frc_teams.find_each do |team|
      client.team_year(team.team_number, event.year)
    end

    Rails.logger.info("[SyncStatboticsJob] Synced Statbotics data for event #{event.tba_key}")
  end
end
