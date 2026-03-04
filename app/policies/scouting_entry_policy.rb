class ScoutingEntryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    owner? || admin_or_lead?
  end

  def destroy?
    admin_or_lead?
  end

  def sync?
    scout?
  end

  private

  def owner?
    record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
