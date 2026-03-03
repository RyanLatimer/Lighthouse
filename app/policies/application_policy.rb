class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  def current_organization
    Current.organization
  end

  def membership
    @membership ||= user.membership_for(current_organization)
  end

  def admin?
    membership&.at_least?("admin")
  end

  def lead?
    membership&.at_least?("lead")
  end

  def analyst?
    membership&.at_least?("analyst")
  end

  def scout?
    membership.present?
  end

  def admin_or_lead?
    admin? || lead?
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    def current_organization
      Current.organization
    end

    def membership
      @membership ||= user.membership_for(current_organization)
    end

    def admin?
      membership&.at_least?("admin")
    end

    def lead?
      membership&.at_least?("lead")
    end

    def analyst?
      membership&.at_least?("analyst")
    end

    def scout?
      membership.present?
    end

    def admin_or_lead?
      admin? || lead?
    end
  end
end
