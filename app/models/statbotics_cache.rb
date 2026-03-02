# frozen_string_literal: true

class StatboticsCache < ApplicationRecord
  # Associations
  belongs_to :frc_team
  belongs_to :event

  # Scopes
  scope :for_event, ->(event) { where(event: event) }
  scope :by_epa, -> { order(epa_mean: :desc) }

  # Returns the total record string "W-L-T"
  def record
    "#{wins}-#{losses}-#{ties}"
  end

  # Returns the qual record string "W-L-T"
  def qual_record
    "#{qual_wins}-#{qual_losses}-0"
  end

  # Returns whether the cache entry is stale (older than the given duration)
  def stale?(duration = 1.hour)
    last_synced_at < duration.ago
  end
end
