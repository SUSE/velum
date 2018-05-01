# frozen_string_literal: true
require "velum/salt"

# This class is responsible to handle the salt events with tag "minion_start".
# When such an event occurs, we want the minion to be saved in our database
# if not already there.
class SaltHandler::CloudBootstrap
  attr_reader :salt_event, :job

  TAG_MATCHER = %r{^salt\/job\/(?<jid>\d+)\/ret\/admin$}

  def self.can_handle_event?(event)
    matches = TAG_MATCHER.match(event.tag)
    return false unless matches
    return false if event.parsed_data["fun"] != "cloud.profile"
    SaltJob.all_open.jids.include? matches[:jid]
  end

  def initialize(salt_event)
    @salt_event = salt_event
    jid = TAG_MATCHER.match(@salt_event.tag)[:jid]
    @job = SaltJob.find_by(jid: jid)
  end

  def process_event
    parsed_data = salt_event.parsed_data
    job.complete!(parsed_data["retcode"] || -1, master_trace: parsed_data["return"])
  end
end
