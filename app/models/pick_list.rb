class PickList < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :user
  belongs_to :organization, optional: true

  # Validations
  validates :name, presence: true
end
