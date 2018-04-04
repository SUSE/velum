# This class is responsible to handle the salt events that are orchestration results.
# Only the bootstrap and update orchestrations will be handled by this class.
class SaltHandler::OrchestrationResult < SaltHandler::Orchestration
  def self.tag_matcher
    %r{salt/run/(\d+)/ret}
  end

  # This method is responsible for all actions needed when the bootstrap/update orchestration
  # has failed. We mark all pending minions as failed if the orchestration failed. If it
  # succeeded, we do nothing, as they will be marked as success by their own highstates events.
  def process_event
    event_data = JSON.parse @salt_event.data

    orchestration_succeeded = event_data["success"]

    update_orchestration orchestration_succeeded: orchestration_succeeded, event_data: event_data

    case self.class.salt_fun_args_match(event_data)
    when "orch.kubernetes", "orch.update"
      update_minions orchestration_succeeded: orchestration_succeeded
    when "orch.removal"
      # Since this orchestration is parametrized is more correct to only update the minions that
      # are specified in the orchestration parameters.
      if orchestration_succeeded
        Minion.pending_removal.where(minion_id: (orchestration.params || {})["target"]).destroy_all
      else
        # rubocop:disable SkipsModelValidations
        Minion.pending_removal.where(minion_id: (orchestration.params || {})["target"]).update_all(
          highstate: Minion.highstates[:removal_failed]
        )
        # rubocop:enable SkipsModelValidations
      end
    end

    true
  end

  private

  def orchestration
    jid, = @salt_event.tag.match(self.class.tag_matcher).captures
    ::Orchestration.find_by jid: jid
  end

  def update_orchestration(orchestration_succeeded:, event_data:)
    orchestration.tap do |orchestration|
      orchestration.status = if orchestration_succeeded
        ::Orchestration.statuses[:succeeded]
      else
        ::Orchestration.statuses[:failed]
      end
      orchestration.finished_at = Time.zone.parse event_data["_stamp"]
    end.save
  end

  def update_minions(orchestration_succeeded:)
    # rubocop:disable SkipsModelValidations
    if orchestration_succeeded
      Minion.pending.update_all highstate: Minion.highstates[:applied]
    else
      Minion.pending.update_all highstate: Minion.highstates[:failed]
    end
    # rubocop:enable SkipsModelValidations
  end
end
