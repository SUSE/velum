namespace :salt do
  desc "Process salt events"
  task process: :environment do
    if ENV["WORKER_ID"].blank?
      puts "Please provide WORKER_ID environment variable that identifies this worker"
      Process.exit 1
    end
    # The salt minion reconciler is a thread that will fetch grains from all the registered
    # minions, and will update those relevant grains in our database, so we can rely on the
    # values on the database when doing polling from the UI or other backend operations
    # using the grains, without the need of having to contact the salt-api, that in turn
    # will contact every minion every time we need them.
    if ENV["SALT_MINION_RECONCILER"] == "true"
      # rubocop:disable Lint/HandleExceptions
      Thread.new do
        loop do
          begin
            Minion.update_grains
          rescue StandardError
          end
          sleep 60
        end
      end
      # rubocop:enable Lint/HandleExceptions
    end
    SaltEvent.process worker_id: ENV["WORKER_ID"]
  end
end
