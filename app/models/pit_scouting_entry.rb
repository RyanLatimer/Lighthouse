# frozen_string_literal: true

class PitScoutingEntry < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :event
  belongs_to :frc_team
  belongs_to :user

  has_many_attached :photos

  enum :status, { submitted: 0, flagged: 1, rejected: 2 }

  validates :client_uuid, uniqueness: true, allow_nil: true

  # Computed accessors for common pit scouting fields
  def drivetrain
    data&.dig("drivetrain") || "Unknown"
  end

  def robot_width
    data&.dig("robot_width")
  end

  def robot_length
    data&.dig("robot_length")
  end

  def robot_height
    data&.dig("robot_height")
  end

  def robot_weight
    data&.dig("robot_weight")
  end

  def mechanisms
    data&.dig("mechanisms") || []
  end

  def auto_capabilities
    data&.dig("auto_capabilities") || []
  end

  def strengths
    data&.dig("strengths") || ""
  end

  def weaknesses
    data&.dig("weaknesses") || ""
  end

  # Build from offline sync data
  def self.from_offline_data(params)
    new(
      user_id: params[:user_id],
      event_id: params[:event_id],
      frc_team_id: params[:frc_team_id],
      organization_id: params[:organization_id],
      data: params[:data] || {},
      notes: params[:notes],
      client_uuid: params[:client_uuid],
      status: params[:status] || :submitted
    )
  end
end
