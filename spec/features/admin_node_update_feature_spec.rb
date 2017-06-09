# frozen_string_literal: true
require "rails_helper"

feature "Manage nodes updates feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
  end

  scenario "Admin node has no update available", js: true do
    allow_any_instance_of(DashboardController).to receive(:admin_status).and_return(0)

    visit authenticated_root_path

    expect(page).not_to have_content("Admin node is running outdated software")
  end

  context "Admin node has an update available" do
    before do
      allow_any_instance_of(DashboardController).to receive(:admin_status).and_return(1)

      visit authenticated_root_path
    end

    scenario "Admin node has an update available", js: true do
      expect(page).to have_content("Admin node is running outdated software")
    end

    scenario "User clicks on admin 'Update admin node'", js: true do
      expect(page).not_to have_content("Reboot to update")

      # clicks on "Update admin node"
      find(".update-admin-btn").click

      expect(page).to have_content("The admin node needs to reboot in order to apply the software update")
      expect(page).to have_content("Reboot to update")
    end

    scenario "User clicks on 'Reboot to update'", js: true do
      # clicks on "Update admin node"
      find(".update-admin-btn").click

      # clicks on "Reboot to update"
      find(".reboot-update-btn").click

      expect(page).to have_content("Rebooting...")
    end
  end

  scenario "Admin node has an update available (failed to update)", js: true do
    allow_any_instance_of(DashboardController).to receive(:admin_status).and_return(2)

    visit authenticated_root_path

    expect(page).to have_content("Admin node is running outdated software (failed to update)")
  end
end