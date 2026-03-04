class Event < ApplicationRecord
  # Associations
  has_many :matches, dependent: :destroy
  has_many :event_teams, dependent: :destroy
  has_many :frc_teams, through: :event_teams
  has_many :scouting_entries, dependent: :destroy
  has_many :pit_scouting_entries, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :simulation_results, dependent: :destroy
  has_many :data_conflicts, dependent: :destroy
  has_many :pick_lists, dependent: :destroy
  has_many :statbotics_caches, class_name: "StatboticsCache", dependent: :destroy

  # Validations
  validates :tba_key, uniqueness: true

  # Scopes
  scope :current_year, -> { where(year: Date.current.year) }
  scope :active, -> {
    today = Date.current
    where("start_date <= ? AND end_date >= ?", today, today)
  }
end
