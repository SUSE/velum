# frozen_string_literal: true

# This class is responsible to handle the salt events with tag "minion_start".
# When such an event occurs, we want the minion to be saved in our database
# if not already there.
class SaltHandler::MinionStart
  attr_reader :salt_event, :event_parsed_data

  def initialize(salt_event)
    @salt_event = salt_event
  end

  # This method is responsible for all actions needed when a minion starts.
  # For now we simply store the Minion in our database.
  def process_event
    # false if a minion with this hostname already exists (uniqueness validation)
    Minion.new(hostname: salt_event.parsed_data["id"]).save
  end
end
