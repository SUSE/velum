# frozen_string_literal: true

require "velum/salt_minion"

# Minion represents the minions that have been registered in this application.
class Minion < ApplicationRecord
  # Raised when Minion doesn't exist
  class NonExistingNode < StandardError; end

  scope :assigned_role, -> { where.not role: nil }
  scope :unassigned_role, -> { where role: nil }

  enum highstate: [:not_applied, :pending, :failed, :applied]
  enum role: [:master, :minion]

  validates :minion_id, presence: true, uniqueness: true
  validates :fqdn, presence: true

  # Example:
  #   Minion.assign_roles(
  #     roles: {
  #       master: [1],
  #       minion: [2, 3]
  #     },
  #     default_role: :dns
  #   )
  def self.assign_roles!(roles: {}, default_role: :minion)
    # Lookup selected masters and minions
    masters = Minion.select_role_members(roles: roles, role: :master)
    minions = Minion.select_role_members(roles: roles, role: :minion)

    # assign roles to each master and minion
    {}.tap do |ret|
      masters.find_each do |master|
        ret[master.minion_id] = master.assign_role(:master)
      end

      minions.find_each do |minion|
        ret[minion.minion_id] = minion.assign_role(:minion)
      end

      # assign default role if there is any minion left with no role
      if default_role
        Minion.where(role: nil).find_each do |minion|
          ret[minion.minion_id] = minion.assign_role(default_role)
        end
      end
    end
  end

  # Prepares an ActiveRecord relation which will return all the members
  # assigned to given role. Additionally, ensures all supplied node IDs
  # exist within the database at the time of calling.
  def self.select_role_members(roles: {}, role: nil)
    node_ids = roles.key?(role) ? roles[role].map(&:to_i) : []

    node_ids.each do |node|
      unless Minion.exists?(id: node)
        raise NonExistingNode, "Failed to process non existing node id: #{node}"
      end
    end

    Minion.where(id: node_ids)
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
    errors.add(:base, "Failed to apply role #{new_role} to #{minion_id}")
    false
  end
  # rubocop:enable SkipsModelValidations

  # Returns the proxy for the salt minion
  def salt
    @salt ||= Velum::SaltMinion.new minion_id: minion_id
  end
end
