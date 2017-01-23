# frozen_string_literal: true
namespace :salt do
  desc "Process salt events"
  task process: :environment do
    if ENV["WORKER_ID"].blank?
      puts "Please provide WORKER_ID environment variable that identifies this worker"
      Process.exit 1
    end
    SaltEvent.process worker_id: ENV["WORKER_ID"]
  end
end
