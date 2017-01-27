# frozen_string_literal: true

require "pharos/salt_minion"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  enum role: [:master, :minion]

  validates :hostname, uniqueness: true

  # rubocop:disable SkipsModelValidations
  # Assigns a role to this minion locally in the database, and send that role
  # to salt subsystem.
  def assign_role(role:)
    return false if salt.roles?
    Minion.transaction do
      update_column :role, role
      salt.assign_role role: role
    end
    true
  rescue Pharos::SaltApi::SaltConnectionException
    false
  end
  # rubocop:enable SkipsModelValidations

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Pharos::SaltMinion.new minion_id: hostname
  end
end
