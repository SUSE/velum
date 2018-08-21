# This class is responsible to handle the salt events that are orchestration triggers.
# Only the bootstrap and update orchestrations will be handled by this class.
class SaltHandler::OrchestrationTrigger < SaltHandler::Orchestration
  def self.tag_matcher
    %r{salt/run/(\d+)/new}
  end

  # This method is responsible for registering the new orchestration trigger.
  def process_event
    event_data = JSON.parse @salt_event.data

    jid, = @salt_event.tag.match(self.class.tag_matcher).captures
    orchestration = ::Orchestration.find_or_create_by(jid: jid) do |orch|
      orch.kind = orch_kind event_data: event_data
      orch.params = (
        event_data["fun_args"].find { |k| k.respond_to?(:key?) && k.key?("pillar") } || {}
      )["pillar"]
    end
    orchestration.started_at = Time.zone.parse event_data["_stamp"]
    orchestration.save
    true
  end

  def orch_kind(event_data:)
    case self.class.salt_fun_args_match(event_data)
    when "orch.kubernetes"
      ::Orchestration.kinds[:bootstrap]
    when "orch.update"
      ::Orchestration.kinds[:upgrade]
    when "orch.migration"
      ::Orchestration.kinds[:migration]
    when "orch.removal"
      ::Orchestration.kinds[:removal]
    when "orch.force-removal"
      ::Orchestration.kinds[:force_removal]
    end
  end
end
