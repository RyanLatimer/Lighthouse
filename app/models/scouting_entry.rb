class ScoutingEntry < ApplicationRecord
  include Scoring

  # Associations
  belongs_to :user
  belongs_to :match, optional: true
  belongs_to :frc_team
  belongs_to :event

  # Enums
  enum :status, { submitted: 0, flagged: 1, rejected: 2 }

  # Validations
  validates :client_uuid, uniqueness: true, allow_nil: true

  # Callbacks
  after_create_commit -> {
    broadcast_prepend_to(
      "scouting_entries_event_#{event_id}",
      target: "scouting_entries",
      partial: "scouting_entries/scouting_entry",
      locals: { scouting_entry: self }
    )
  }

  # --- Computed methods reading from JSONB data column ---

  # Total fuel scored across all phases
  def total_fuel_made
    dig_int("auton_fuel_made") + dig_int("teleop_fuel_made") + dig_int("endgame_fuel_made")
  end

  # Total fuel missed across all phases
  def total_fuel_missed
    dig_int("auton_fuel_missed") + dig_int("teleop_fuel_missed") + dig_int("endgame_fuel_missed")
  end

  # Fuel accuracy as a percentage (0-100). Returns 0.0 when no attempts.
  def fuel_accuracy
    total = total_fuel_made + total_fuel_missed
    return 0.0 if total.zero?

    (total_fuel_made.to_f / total * 100).round(1)
  end

  # Total points for this entry
  def total_points
    points = total_fuel_made * FUEL_POINT_VALUE

    points += AUTON_CLIMB_POINTS if ActiveModel::Type::Boolean.new.cast(data&.dig("auton_climb"))

    climb_level = data&.dig("endgame_climb").to_s
    points += CLIMB_POINTS.fetch(climb_level, 0)

    points
  end

  # Auton points for this entry (auton fuel + auton climb bonus)
  def auton_points
    pts = dig_int("auton_fuel_made") * FUEL_POINT_VALUE
    pts += AUTON_CLIMB_POINTS if ActiveModel::Type::Boolean.new.cast(data&.dig("auton_climb"))
    pts
  end

  # Climb points for this entry (auton climb + endgame climb)
  def climb_points
    pts = 0
    pts += AUTON_CLIMB_POINTS if ActiveModel::Type::Boolean.new.cast(data&.dig("auton_climb"))
    pts += CLIMB_POINTS.fetch(data&.dig("endgame_climb").to_s, 0)
    pts
  end

  # Defense rating (1-5, 0 means not rated)
  def defense_rating
    dig_int("defense_rating")
  end

  # Returns the array of autonomous actions from the JSONB data
  def auton_actions
    data&.dig("auton_actions") || []
  end

  # Build a ScoutingEntry from offline/sync data
  def self.from_offline_data(params)
    new(
      user_id: params[:user_id],
      match_id: params[:match_id],
      frc_team_id: params[:frc_team_id],
      event_id: params[:event_id],
      data: params[:data] || {},
      notes: params[:notes],
      photo_url: params[:photo_url],
      client_uuid: params[:client_uuid],
      status: params[:status] || :submitted
    )
  end

  private

  # Safely dig an integer value from the JSONB data hash
  def dig_int(key)
    data&.dig(key).to_i
  end
end
