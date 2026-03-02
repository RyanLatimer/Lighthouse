class SimulationResultPolicy < ApplicationPolicy
  def index?
    analyst? || admin_or_lead?
  end

  def show?
    analyst? || admin_or_lead?
  end

  def create?
    analyst? || admin_or_lead?
  end

  def destroy?
    admin_or_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
