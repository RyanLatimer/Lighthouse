class ScoutingAssignmentPolicy < ApplicationPolicy
  def index?
    scout?
  end

  def bulk_create?
    admin?
  end

  def bulk_destroy?
    admin?
  end

  def toggle?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if admin?

      scope.where(user_id: user.id)
    end
  end
end
