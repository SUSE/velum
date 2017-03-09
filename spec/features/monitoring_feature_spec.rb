# frozen_string_literal: true
require "rails_helper"

feature "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    Minion.create!(hostname: "minion0.k8s.local", role: "master")
    visit authenticated_root_path
  end

  scenario "It updates the status of the minions automatically", js: true do
    # We poll every 5 seconds so the default Capybara wait time might not be enough
    using_wait_time 10 do
      expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-circle-o")
      Minion.first.update!(highstate: "pending")
      expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-refresh")
    end
  end
end
