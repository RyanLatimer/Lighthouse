class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :scouting_entries, dependent: :destroy
  has_many :pit_scouting_entries, dependent: :destroy
  has_many :pick_lists, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :simulation_results, dependent: :destroy

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :team_number, presence: true

  # Scopes
  scope :scouts, -> { joins(:roles).where(roles: { name: "scout" }) }

  # Generate API token
  before_create :generate_api_token

  # Returns "First Last"
  def full_name
    "#{first_name} #{last_name}"
  end

  # Returns the highest-priority role name (legacy Rolify).
  ROLE_PRIORITY = %w[admin lead analyst scout].freeze

  def role_name
    ROLE_PRIORITY.find { |r| has_role?(r) } || "scout"
  end

  # Membership-based role methods for a specific organization
  def membership_for(organization)
    return nil unless organization

    memberships.find_by(organization: organization)
  end

  def role_in(organization)
    membership_for(organization)&.role || "scout"
  end

  def at_least?(role, organization)
    membership = membership_for(organization)
    return false unless membership

    membership.at_least?(role)
  end

  def owner_of?(organization)
    membership_for(organization)&.owner?
  end

  def admin_of?(organization)
    membership = membership_for(organization)
    return false unless membership

    membership.at_least?(:admin)
  end

  def lead_of?(organization)
    membership = membership_for(organization)
    return false unless membership

    membership.at_least?(:lead)
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.hex(32))
  end

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end
end
