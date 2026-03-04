class DataConflictPolicy < ApplicationPolicy
  def index?
    analyst?
  end

  def resolve?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
