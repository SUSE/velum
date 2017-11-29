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

    orchestration_succeeded = event_data["success"] && event_data["return"]["retcode"].zero?

    update_orchestration orchestration_succeeded: orchestration_succeeded, event_data: event_data
    update_minions orchestration_succeeded: orchestration_succeeded

    true
  end

  private

  def update_orchestration(orchestration_succeeded:, event_data:)
    jid, = @salt_event.tag.match(self.class.tag_matcher).captures
    ::Orchestration.find_by(jid: jid).tap do |orchestration|
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
