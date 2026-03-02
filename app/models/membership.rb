# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum :role, { scout: 0, analyst: 1, lead: 2, admin: 3, owner: 4 }

  validates :user_id, uniqueness: { scope: :organization_id }
  validates :role, presence: true

  # Role hierarchy check: does this membership have at least the given role level?
  ROLE_PRIORITY = %w[scout analyst lead admin owner].freeze

  def at_least?(minimum_role)
    ROLE_PRIORITY.index(role.to_s) >= ROLE_PRIORITY.index(minimum_role.to_s)
  end
end
