# frozen_string_literal: true

require "velum/salt_minion"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  scope :assigned_role, -> { where.not role: nil }
  scope :unassigned_role, -> { where role: nil }

  enum highstate: [:not_applied, :pending, :failed, :applied]
  enum role: [:master, :worker]
  enum status: [:unknown, :update_needed, :update_failed, :rebooting]

  validates :minion_id, presence: true, uniqueness: true
  validates :fqdn, presence: true

  # NOTE: this should be moved into a proper DB column as we do for highstates.
  attr_accessor :update_status

  # Example:
  #   Minion.assign_roles(
  #     roles: {
  #       master: [1],
  #       worker: [2, 3]
  #     },
  #     default_role: :dns
  #   )
  def self.assign_roles(roles: {}, default_role: nil, remote: false)
    # Lookup selected masters and workers
    masters = Minion.select_role_members(roles: roles, role: :master)
    minions = Minion.select_role_members(roles: roles, role: :worker)

    # assign roles to each master and worker
    {}.tap do |ret|
      masters.find_each do |master|
        ret[master.minion_id] = master.assign_role(:master, remote: remote)
      end

      minions.find_each do |minion|
        ret[minion.minion_id] = minion.assign_role(:worker, remote: remote)
      end

      # assign default role if there is any minion left with no role
      if default_role
        Minion.where(role: nil).find_each do |minion|
          ret[minion.minion_id] = minion.assign_role(default_role, remote: remote)
        end
      end
    end
  end

  # Prepares an ActiveRecord relation which will return all the members
  # assigned to given role.
  def self.select_role_members(roles: {}, role: nil)
    Minion.where id: (roles.key?(role) ? roles[role].map(&:to_i) : [])
  end

  # Returns the update status for the given minion ID. The needed and the
  # failed arguments are the results as given by salt, with the form of an array
  # of hashes.
  def self.computed_status(id, needed, failed)
    if failed.first && !failed.first[id].blank?
      Minion.statuses[:update_failed]
    elsif needed.first && !needed.first[id].blank?
      Minion.statuses[:update_needed]
    else
      Minion.statuses[:unknown]
    end
  end

  # rubocop:disable SkipsModelValidations
  # Assigns a role to this minion locally in the database, and send that role
  # to salt subsystem if remote is true.
  def assign_role(new_role, remote: false)
    Minion.transaction do
      # We set highstate to pending only if we are gonna call salt
      highstate = remote ? :pending : :not_applied
      success   = update_columns role:      Minion.roles[new_role],
                                 highstate: Minion.highstates[highstate]
      if success && remote
        salt.assign_role
      else
        success
      end
    end
  rescue Velum::SaltApi::SaltConnectionException
    errors.add :base, "Failed to apply role #{new_role} to #{minion_id}"
    false
  end
  # rubocop:enable SkipsModelValidations

  # Updates all nodes with a grain of `tx_update_reboot_needed: True` with a
  # highstate = pending, and persists it to the database
  def self.mark_pending_update
    needed, failed = ::Velum::Salt.update_status(targets: "*", cached: true)
    minions = Minion.assigned_role
    minions.each do |minion|
      if Minion.computed_status(minion.minion_id, needed, failed) == Minion.statuses[:update_needed]
        Minion.find_by(minion_id: minion.minion_id).update(highstate: Minion.highstates[:pending])
      end
    end
  end

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Velum::SaltMinion.new minion: self
  end
end
