class GameConfig < ApplicationRecord

  # Validations
  validates :year, presence: true
  validates :game_name, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Returns the current active GameConfig
  def self.current
    active.order(year: :desc).first
  end
end
