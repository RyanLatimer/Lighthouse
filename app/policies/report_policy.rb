class ReportPolicy < ApplicationPolicy
  def index?
    analyst? || admin_or_lead?
  end

  def show?
    analyst? || admin_or_lead?
  end

  def create?
    admin_or_lead?
  end

  def update?
    admin_or_lead?
  end

  def destroy?
    admin_or_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin_or_lead?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
