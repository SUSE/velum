# frozen_string_literal: true

require "velum/salt_minion"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  # Raised when Minion doesn't exist
  class NonExistingMinion < StandardError; end

  scope :assigned_role, -> { where.not role: nil }
  scope :unassigned_role, -> { where role: nil }

  enum highstate: [:not_applied, :pending, :failed, :applied]
  enum role: [:master, :minion]

  validates :hostname, presence: true, uniqueness: true

  # Example:
  #   Minion.assign_roles(
  #     roles: {
  #       master: 1,
  #       minion: [2, 3]
  #     },
  #     default_role: :dns
  #   )
  def self.assign_roles!(roles: {}, default_role: :minion)
    requested_master = roles[:master]
    requested_minions = roles[:minion] || (Minion.unassigned_role.pluck(:id) - [requested_master])
    if !requested_master.blank? && !Minion.exists?(id: requested_master)
      raise NonExistingMinion, "Failed to process non existing minion id: #{requested_master}"
    end
    master = Minion.find(requested_master)
    # choose requested minions or all other than master
    minions = Minion.where(id: requested_minions).where.not(id: requested_master)

    # assign master if requested
    {}.tap do |ret|
      ret[master.hostname] = master.assign_role(:master) if master

      minions.find_each do |minion|
        ret[minion.hostname] = minion.assign_role(:minion)
      end

      # assign default role if there is any minion left with no role
      if default_role
        Minion.where(role: nil).find_each do |minion|
          ret[minion.hostname] = minion.assign_role(default_role)
        end
      end
    end
  end

  # rubocop:disable SkipsModelValidations
  # Assigns a role to this minion locally in the database, and send that role
  # to salt subsystem.
  def assign_role(new_role)
    return false if role.present?
    success = false

    Minion.transaction do
      # We set highstate to pending since we just assigned a new role
      success = update_columns(role:      Minion.roles[new_role],
                               highstate: Minion.highstates[:pending])
      break unless success
      success = salt.assign_role new_role
    end
    success
  rescue Velum::SaltApi::SaltConnectionException
    errors.add(:base, "Failed to apply role #{new_role} to #{hostname}")
    false
  end
  # rubocop:enable SkipsModelValidations

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Velum::SaltMinion.new minion_id: hostname
  end
end
