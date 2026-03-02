class FrcTeam < ApplicationRecord
  # Associations
  has_many :event_teams, dependent: :destroy
  has_many :events, through: :event_teams
  has_many :match_alliances, dependent: :destroy
  has_many :matches, through: :match_alliances
  has_many :scouting_entries, dependent: :destroy
  has_many :pit_scouting_entries, dependent: :destroy
  has_many :predictions, through: :matches

  # Validations
  validates :team_number, presence: true, uniqueness: true

  # Scopes
  scope :at_event, ->(event) {
    joins(:event_teams).where(event_teams: { event_id: event.id })
  }

  # Returns the TBA-style key for this team (e.g. "frc254")
  def tba_key
    "frc#{team_number}"
  end
end
