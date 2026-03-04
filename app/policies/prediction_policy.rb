class PredictionPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    analyst?
  end

  def show?
    analyst?
  end

  def generate?
    admin?
  end
end
