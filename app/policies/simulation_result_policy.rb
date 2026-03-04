class SimulationResultPolicy < ApplicationPolicy
  def index?
    analyst?
  end

  def show?
    analyst?
  end

  def create?
    analyst?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
