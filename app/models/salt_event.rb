# This class wraps salt's events. Salt stores the events in the same database
# we use for this application. This model is mapped to the same table salt-master
# writes events into.
class SaltEvent < ApplicationRecord
  # Processing of a single event shouldn't take more than than 5 minutes.
  # We consider events which were taken 5 minutes ago but not yet processed as
  # if the worker died so we reassign them for processing.
  PROCESS_TIMEOUT_MIN = 5
  NO_EVENTS_TIMEOUT_SEC = 5

  ENABLED_EVENT_HANDLERS = [
    SaltHandler::MinionStart,
    SaltHandler::MinionHighstate,
    SaltHandler::OrchestrationTrigger,
    SaltHandler::OrchestrationResult,
    SaltHandler::CloudBootstrap,
    SaltHandler::AuthEvent
  ].freeze

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
      unless process_next_event(worker_id: worker_id)
        purge_jobs_older_than 24.hours.ago
        sleep NO_EVENTS_TIMEOUT_SEC
      end
    end
    # :nocov:
  end

  # Purge jobs older than timestamp
  def self.purge_jobs_older_than(date)
    # :nocov:
    ActiveRecord::Base.connection.execute("
     delete from `jids` where jid in (select distinct jid from salt_returns
                                      where alter_time < #{date.to_i})
    ")
    [:events, :returns].each do |table|
      ActiveRecord::Base.connection.execute("
        delete from `salt_#{table}` where alter_time < #{date.to_i};
    ")
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
    # rubocop:enable SkipsModelValidations

    return false if taken_event.zero?

    SaltEvent.where(worker_id: worker_id, processed_at: nil)
             .where.not(taken_at: nil).limit(1).each(&:process!)
  end

  # Memoizes the @handler instance which is responsible to process this event.
  def handler
    return @handler if @handler

    klass = ENABLED_EVENT_HANDLERS.find do |handler_class|
      handler_class.can_handle_event?(self)
    end

    klass.new(self) if klass
  end

  # Calls the handler and marks this event as processed.
  def process!
    handler.try(:process_event)

    # rubocop:disable SkipsModelValidations
    update_column(:processed_at, Time.current)
    # rubocop:enable SkipsModelValidations
  end

  def parsed_data
    JSON.parse(data)
  end
end
