# This is a subclass for common logic across Orchestration trigger and result.
class SaltHandler::Orchestration
  attr_reader :salt_event

  ORCHESTRATIONS = [
    "orch.kubernetes",
    "orch.update",
    "orch.migration",
    "orch.removal",
    "orch.force-removal"
  ].freeze

  def self.tag_matcher
    raise "no tag matcher specified"
  end

  def self.can_handle_event?(event)
    return false unless event.tag =~ tag_matcher
    event_data = JSON.parse event.data
    event_data["fun"] == "runner.state.orchestrate" && salt_fun_args_match(event_data)
  end

  def self.salt_fun_args_match(event_data)
    fun_args = event_data["fun_args"]

    ORCHESTRATIONS.each do |o|
      # rubocop:disable Lint/HandleExceptions,Style/GuardClause
      begin
        if fun_args.last["pillar"] && fun_args.last["pillar"].symbolize_keys == { migration: true }
          return "orch.migration"
        elsif [fun_args.first, fun_args.first["mods"]].include? o
          return o
        end
      rescue StandardError
      end
      # rubocop:enable Lint/HandleExceptions,Style/GuardClause
    end

    nil
  end

  def initialize(salt_event)
    @salt_event = salt_event
  end
end
