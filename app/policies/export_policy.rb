class ExportPolicy < ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record # will be :export symbol
  end

  def csv?
    analyst?
  end

  def pdf?
    analyst?
  end

  def excel?
    analyst?
  end

  def json?
    analyst?
  end
end
