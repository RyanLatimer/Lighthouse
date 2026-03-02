class PredictionPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true
  end

  def show?
    true
  end

  def generate?
    admin_or_lead?
  end
end
