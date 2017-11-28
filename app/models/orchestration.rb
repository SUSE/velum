# frozen_string_literal: true

require "velum/salt"
require "velum/salt_orchestration"

# Orchestration represents a salt orchestration event
class Orchestration < ApplicationRecord
  class OrchestrationAlreadyRan < StandardError; end

  enum kind: [:bootstrap, :upgrade]
  enum status: [:in_progress, :succeeded, :failed]

  after_create :update_minions

  # rubocop:disable Rails/SkipsModelValidations
  def run
    raise OrchestrationAlreadyRan unless jid.blank?
    update_column :status, Orchestration.statuses[:in_progress]
    _, job = case kind
             when "bootstrap"
               Velum::Salt.orchestrate
             when "upgrade"
               Velum::Salt.update_orchestration
    end
    update_column :jid, job["return"].first["jid"]
    true
  end
  # rubocop:enable Rails/SkipsModelValidations

  def self.run(kind: :bootstrap)
    Orchestration.create!(kind: kind).tap(&:run)
  end

  def self.retryable?(kind: :bootstrap)
    case kind
    when :bootstrap
      Orchestration.bootstrap.last.try(:status) == "failed"
    when :upgrade
      Orchestration.upgrade.last.try(:status) == "failed"
    end
  end

  # Returns the proxy for the salt orchestration
  def salt
    @salt ||= Velum::SaltOrchestration.new orchestration: self
  end

  private

  def update_minions
    case kind
    when "bootstrap"
      Minion.mark_pending_bootstrap
    when "upgrade"
      Minion.mark_pending_update
    end
  end
end
