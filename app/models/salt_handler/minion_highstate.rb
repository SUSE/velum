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

  # This method is responsible for all actions needed when a minion reaches highstate.
  # We set the highstate result for this minion in particular.
  def process_event
    minion_id = salt_event.tag.match(TAG_MATCHER)[1]
    return false unless minion_id

    minion = Minion.find_by minion_id: minion_id
    return false unless minion

    data = JSON.parse(salt_event.data)

    highstate_succeeded = data["success"] && data["retcode"].zero?
    # rubocop:disable SkipsModelValidations
    minion.update_column(:highstate, Minion.highstates[:failed]) unless highstate_succeeded
    # rubocop:enable SkipsModelValidations

    true
  end
end
