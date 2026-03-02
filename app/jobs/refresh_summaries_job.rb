# frozen_string_literal: true

class RefreshSummariesJob < ApplicationJob
  queue_as :default

  # Refreshes the TeamEventSummary materialized view and optionally
  # runs conflict detection for the given event.
  def perform(event_id, detect_conflicts: true)
    event = Event.find_by(id: event_id)
    return unless event

    # Refresh the materialized view
    TeamEventSummary.refresh!

    # Optionally detect new conflicts
    if detect_conflicts
      service = AggregationService.new(event)
      new_conflicts = service.detect_conflicts!
      Rails.logger.info("[RefreshSummariesJob] Found #{new_conflicts.size} new conflicts for event #{event.name}")
    end

    Rails.logger.info("[RefreshSummariesJob] Refreshed summaries for event #{event.name}")
  end
end
