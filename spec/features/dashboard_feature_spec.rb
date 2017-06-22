# frozen_string_literal: true
require "rails_helper"

feature "Dashboard" do
  describe "Downloading kubeconfig" do
    let!(:user) { create(:user) }

    before do
      login_as user, scope: :user
      Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
      Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker")
      setup_stubbed_update_status!
      setup_stubbed_pending_minions!
      visit authenticated_root_path
    end

    # rubocop:disable RSpec/ExampleLength
    it "enables/disables the download button depending on the current state", js: true do
      # Bootstrapping, the button is disabled.
      el = find("#download-kubeconfig")
      expect(el[:disabled]).to eq "disabled"

      # Fake that bootstrapping ended successfully.
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(highstate: Minion.highstates[:applied])
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path

      el = find("#download-kubeconfig")
      wait_until { !find("#download-kubeconfig")[:disabled] }
      expect(el[:disabled]).to be_falsey
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
