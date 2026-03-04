# frozen_string_literal: true

class AutoSyncEventJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  COOLDOWN = 5.minutes

  # Runs the heavier downstream sync jobs (Statbotics EPA, materialized
  # views, predictions) after the inline TBA sync in the controller.
  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

    RefreshSummariesJob.perform_later(event.id)
    SyncStatboticsJob.perform_later(event.id)
    RefreshPredictionsJob.perform_later(event.id)

    Rails.logger.info("[AutoSyncEventJob] Enqueued downstream sync for event #{event.tba_key}")
  end
end
