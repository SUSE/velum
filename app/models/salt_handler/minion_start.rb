# frozen_string_literal: true
require "velum/salt"

# This class is responsible to handle the salt events with tag "minion_start".
# When such an event occurs, we want the minion to be saved in our database
# if not already there.
class SaltHandler::MinionStart
  attr_reader :salt_event

  def self.can_handle_event?(event)
    event.tag == "minion_start"
  end

  def initialize(salt_event)
    @salt_event = salt_event
  end

  # This method is responsible for all actions needed when a minion starts.
  # For now we simply store the Minion in our database.
  def process_event
    parsed_data = salt_event.parsed_data

    # Ignore the ca and the dashboard minions. It shouldn't be used as part of
    # the k8s cluster.
    id = parsed_data["id"]
    return false if id == "ca" || id == "admin"

    minion_info = Velum::Salt.minions[id]

    # false if a minion with this minion_id or fqdn already exists (uniqueness validation)
    Minion.new(minion_id: id, fqdn: minion_info["fqdn"]).save
  end
end
