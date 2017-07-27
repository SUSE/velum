# frozen_string_literal: true
# A simple module containing some utility methods.
module Utils
  # Stubs the ::Velum::Salt.update_status method with the given data.
  def setup_stubbed_update_status!(stubbed: [[], []])
    allow(::Velum::Salt).to receive(:update_status).and_return(stubbed)
  end

  # Stubs the ::Velum::Salt.pending_minions method with the given data.
  def setup_stubbed_pending_minions!(stubbed: [""])
    allow(::Velum::Salt).to receive(:pending_minions).and_return(stubbed)
  end

  # Initializes the necessary fields for the setup to be considered completed
  def setup_done(dashboard: true, apiserver: true)
    Pillar.create pillar: Pillar.all_pillars[:dashboard], value: "localhost" if dashboard
    Pillar.create pillar: Pillar.all_pillars[:apiserver], value: "api.example.com" if apiserver
  end

  def setup_undone
    Pillar.delete_all
  end
end

RSpec.configure { |config| config.include Utils }
