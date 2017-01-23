# frozen_string_literal: true

# This class wraps salt's events. Salt stores the events in the same database
# we use for this application. This model is mapped to the same table salt-master
# writes events into.
class SaltEvent < ApplicationRecord
  # Processing of a single event shouldn't take more than than 5 minutes.
  # We consider events which were taken 5 minutes ago but not yet processed as
  # if the worker died so we reassign them for processing.
  PROCESS_TIMEOUT_MIN = 5
  NO_EVENTS_TIMEOUT_SEC = 5

  scope :not_processed, -> { where(processed_at: nil) }
  scope :not_assigned, -> { where(worker_id: nil) }

  # An event can be assigned to #my_worker when any of the following is true:
  # - the event is not assigned to any worker
  # - the event is already assigned to #my_worker
  # - the event is assigned to any worker but more than
  #   PROCESS_TIMEOUT_MIN minutes ago
  #
  # NOTE [Rails 5] Split this in separate scopes when we move to Rails 5 where
  # ActiveRecord supports OR queries.
  scope :assignable_to_worker, lambda { |worker_id|
    where("worker_id IS NULL OR (worker_id = ?) OR taken_at < ?",
          worker_id, PROCESS_TIMEOUT_MIN.minutes.ago)
  }

  # Processes one salt event at a time and sleeps
  # NO_EVENTS_TIMEOUT_SEC seconds if none is available for processing.
  def self.process(worker_id:)
    # :nocov:
    logger.info "Salt event processor #{worker_id} started at #{Time.current}"

    loop do
      sleep(NO_EVENTS_TIMEOUT_SEC) unless process_next_event(worker_id: worker_id)
    end
    # :nocov:
  end

  # Fetches the next processable event for the specified worker and calls
  # process! on it. It returns false if no event is available for processing
  # by the specified worker.
  def self.process_next_event(worker_id:)
    # rubocop:disable SkipsModelValidations
    taken_event = SaltEvent
                  .not_processed.assignable_to_worker(worker_id)
                  .limit(1).update_all(worker_id: worker_id, taken_at: Time.current)

    return false if taken_event.zero?

    SaltEvent.where(worker_id: worker_id, processed_at: nil)
             .where.not(taken_at: nil).limit(1).first.process!
  end

  # Memoizes the @handler instance which is responsible to process this event.
  def handler
    return @handler if @handler

    case tag
    when "minion_start"
      @handler = SaltHandler::MinionStart.new(self)
    end
  end

  # Calls the handler and marks this event as processed.
  def process!
    handler&.process_event

    update_column(:processed_at, Time.current)
  end

  def parsed_data
    JSON.parse(data)
  end
end
