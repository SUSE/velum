# frozen_string_literal: true

require "velum/salt_minion"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  # Raised when trying to bootstrap more minions than those available
  # (E.g. assign roles [:master, :minion] when there is only one minion)
  class NotEnoughMinions < StandardError; end
  # Raised when we fail to assign a role on a minion
  class CouldNotAssignRole < StandardError; end

  enum highstate: [:not_applied, :pending, :failed, :applied]
  enum role: [:master, :minion]

  validates :hostname, presence: true, uniqueness: true

  # This method is used to assign the specified roles to Minions which do not
  # have a roles already assigned (available minions).
  # roles param are the roles we absolutely have to assign. If we can't assign
  # one of those, the method will raise.
  # default_role param can be set if we want all the rest of the available
  # minions to get a default role.
  # Returns the ids of the minions on which a roles has been assigned.
  def self.assign_roles(roles: [], default_role: nil)
    minions = Minion.where(role: nil)

    # only the needed number of minions or all if we have a default role
    minions = minions.limit(roles.size) unless default_role

    raise NotEnoughMinions if minions.count < roles.size

    assigned_ids = []
    minions.find_each do |minion|
      unless minion.assign_role(roles.pop || default_role)
        raise CouldNotAssignRole
      end
      assigned_ids << minion.id
    end

    assigned_ids
  end

  # rubocop:disable SkipsModelValidations
  # Assigns a role to this minion locally in the database, and send that role
  # to salt subsystem.
  def assign_role(new_role)
    return false if role.present?

    Minion.transaction do
      # We set highstate to pending since we just assigned a new role
      update_columns(role:      Minion.roles[new_role],
                     highstate: Minion.highstates[:pending])
      salt.assign_role new_role
    end
    true
  rescue Velum::SaltApi::SaltConnectionException
    errors.add(:base, "Failed to apply role #{new_role} to #{self.hostname}")
    false
  end
  # rubocop:enable SkipsModelValidations

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Velum::SaltMinion.new minion_id: hostname
  end
end
