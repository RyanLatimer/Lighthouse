class ExportPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record # will be :export symbol
  end

  def csv?
    admin_or_lead?
  end

  def pdf?
    admin_or_lead?
  end

  def excel?
    admin_or_lead?
  end

  def json?
    admin_or_lead?
  end
end
