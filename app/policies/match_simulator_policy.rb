class MatchSimulatorPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record # will be :match_simulator symbol
  end

  def new?
    analyst?
  end

  def create?
    analyst?
  end
end
