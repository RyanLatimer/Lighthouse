# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :events, dependent: :destroy
  has_many :scouting_entries, dependent: :destroy
  has_many :pit_scouting_entries, dependent: :destroy
  has_many :pick_lists, dependent: :destroy
  has_many :data_conflicts, dependent: :destroy
  has_many :game_configs, dependent: :destroy
  has_many :predictions, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :simulation_results, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if slug.present?

    base = name.to_s.parameterize
    candidate = base
    counter = 1
    while Organization.exists?(slug: candidate)
      candidate = "#{base}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
