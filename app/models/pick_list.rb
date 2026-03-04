class PickList < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :user

  # Validations
  validates :name, presence: true
end
