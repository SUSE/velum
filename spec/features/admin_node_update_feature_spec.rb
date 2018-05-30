require "rails_helper"

describe "Manage nodes updates feature", js: true do
  let!(:user) { create(:user) }

  before do
    setup_done
    login_as user, scope: :user
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
    setup_stubbed_pending_minions!
  end

  it "Admin node has no update available" do
    visit authenticated_root_path

    expect(page).not_to have_content("Update admin node")
  end

  context "when the admin node has an update available" do
    before do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                  tx_update_failed:        false)
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path
    end

    it "Admin node has an update available" do
      expect(page).to have_content("Admin node is running outdated software")
    end

    it "User clicks on admin 'Update admin node'" do
      find(".update-admin-btn").click

      expect(page).to have_content("The admin node needs to reboot "\
                                   "in order to apply the software update")
      expect(page).to have_content("Reboot to update")
    end

    # rubocop:disable RSpec/ExampleLength
    it "User clicks on 'Reboot to update'" do
      allow(::Velum::Salt).to receive(:call).and_return(true)

      find(".update-admin-btn").click

      # wait modal to appear
      expect(page).to have_content("Reboot to update")

      # clicks on "Reboot to update"
      find(".reboot-update-btn").click

      wait_for_ajax

      expect(::Velum::Salt).to have_received(:call).once
    end
    # rubocop:enable RSpec/ExampleLength
  end

  it "shows admin update failed message" do
    # rubocop:disable Rails/SkipsModelValidations
    Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: false,
                                                tx_update_failed:        true)
    # rubocop:enable Rails/SkipsModelValidations
    visit authenticated_root_path

    expect(page).to have_content("An error occurred during the admin node update process")
    expect(page).not_to have_content("UPDATE ADMIN NODE")
  end

  it "shows admin update failed message and update button" do
    # rubocop:disable Rails/SkipsModelValidations
    Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                tx_update_failed:        true)
    # rubocop:enable Rails/SkipsModelValidations
    visit authenticated_root_path

    expect(page).to have_content("An error occurred during the admin node update process")
    expect(page).to have_content("UPDATE ADMIN NODE")
  end
end
