# frozen_string_literal: true

# This class is responsible to handle the salt events that are highstate job
# successful returns. When we run a highstate successfully on a minion then
# that Minion must be have the highstate attribute updated.
class SaltHandler::MinionHighstate
  attr_reader :salt_event

  TAG_MATCHER = %r{salt/job/\d+/ret/(.*)}

  def self.can_handle_event?(event)
    event.tag =~ TAG_MATCHER &&
      JSON.parse(event.data)["fun"] == "state.highstate"
  end

  def initialize(salt_event)
    @salt_event = salt_event
  end

  # This method is responsible for all actions needed when a minion starts.
  # For now we simply store the Minion in our database.
  def process_event
    minion_id = salt_event.tag.match(TAG_MATCHER)[1]
    return false unless minion_id

    # After applying a highstate once, it is applied again and again.
    # Salt probably tries to make sure it stays applied. We don't need to process
    # those events. We only need to process a highstate if one is pending.
    minion = Minion.find_by(
      hostname:  minion_id,
      highstate: Minion.highstates[:pending]
    )
    return false unless minion

    data = JSON.parse(salt_event.data)

    new_highstate = Minion.highstates[data["success"] ? :applied : :failed]
    # rubocop:disable SkipsModelValidations
    minion.update_column(:highstate, new_highstate)
    # rubocop:enable SkipsModelValidations
  end
end
