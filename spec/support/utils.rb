# A simple module containing some utility methods.
module Utils
  # Stubs the ::Velum::Salt.pending_minions method with the given data.
  def setup_stubbed_pending_minions!(stubbed: [""])
    allow(::Velum::Salt).to receive(:pending_minions).and_return(stubbed)
  end

  # Stubs the ::Velum::Salt.remove_minion method with the given data.
  def setup_stubbed_remove_minion!(stubbed: "")
    allow(::Velum::Salt).to receive(:remove_minion).and_return(true)
    Minion.remove_minion(stubbed)
  end

  # Stubs the ::Velum::Salt.reject_minion method with the given data.
  def setup_stubbed_reject_minion!(*)
    allow(::Velum::Salt).to receive(:reject_minion).and_return(true)
  end

  # Initializes the necessary fields for the setup to be considered completed
  def setup_done(dashboard: true, apiserver: true)
    Pillar.create pillar: Pillar.all_pillars[:dashboard], value: "localhost" if dashboard
    Pillar.create pillar: Pillar.all_pillars[:apiserver], value: "api.example.com" if apiserver
  end

  def setup_undone
    Pillar.delete_all
  end

  def ensure_pillar_refresh
    VCR.use_cassette(
      "salt/refresh_pillar",
      allow_unused_http_interactions: false,
      allow_playback_repeats:         true,
      record:                         :none
    ) do
      yield
    end
  end
end

RSpec.configure { |config| config.include Utils }
