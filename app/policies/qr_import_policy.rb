class QrImportPolicy < ApplicationPolicy
  # Only analysts and admins can access the QR scanner and import entries
  def scanner?
    analyst?
  end

  def import?
    analyst?
  end
end
