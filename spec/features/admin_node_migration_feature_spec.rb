require "rails_helper"

describe "Manage nodes migration feature", js: true do
  let!(:user) { create(:user) }

  before do
    setup_done
    login_as user, scope: :user
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
    setup_stubbed_pending_minions!
  end

  it "Admin node has no migration available" do
    visit authenticated_root_path

    expect(page).not_to have_content("Migrate admin node")
  end

  context "when the admin node has a migration available" do
    before do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(
        tx_update_migration_available:     true,
        tx_update_migration_mirror_synced: true,
        tx_update_migration_notes:         "https://release-notes-url",
        tx_update_migration_newversion:    "SUSE CaaS Platform 3.1 x86_64"
      )
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path
    end

    it "Admin node has a migration available" do
      expect(page).to have_content("Cluster has migration available")
    end

    it "User clicks on admin 'Migrate admin node'" do
      find(".migrate-admin-btn").click

      expect(page).to have_content("A new version of SUSE CaaS Platform is available")
      expect(page).to have_content("Migrate admin")
    end

    # rubocop:disable RSpec/ExampleLength
    it "User clicks on 'Migrate admin'" do
      allow(Orchestration).to receive(:run).with(kind: :migration)

      find(".migrate-admin-btn").click

      # wait modal to appear
      expect(page).to have_content("Migrate admin")

      # clicks on "Migrate admin"
      find(".trigger-migrate-admin-btn").click

      wait_for_ajax

      expect(Orchestration).to have_received(:run).with(kind: :migration).once
    end
    # rubocop:enable RSpec/ExampleLength
  end

  context "when SMT/RMT mirror is out of sync" do
    before do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(
        tx_update_migration_available:     true,
        tx_update_migration_mirror_synced: false,
        tx_update_migration_notes:         "https://release-notes-url",
        tx_update_migration_newversion:    "SUSE CaaS Platform 3.1 x86_64"
      )
      # rubocop:enable Rails/SkipsModelValidations
      allow(::Velum::Salt).to receive(:call)
      allow(Minion).to receive(:update_grains)

      visit authenticated_root_path
    end

    it "shows a warning that the mirrors are out of sync" do
      expect(page).to have_content("Your local RMT/SMT mirror looks like it's out of sync")
    end

    it "shows another warning before migration that the mirrors are out of sync" do
      find(".migrate-admin-btn").click

      # wait for modal to appear
      expect(page).to have_content("Migrate admin")

      # clicks on "Migrate admin"
      find(".trigger-migrate-admin-btn").click

      expect(page).to have_content("Cannot run migration with out of date mirrors")
    end

    # rubocop:disable RSpec/ExampleLength
    it "checks again if the mirrors are in sync" do
      find(".migrate-admin-btn").click

      # wait for modal to appear
      expect(page).to have_content("Migrate admin")

      # clicks on "Migrate admin"
      find(".trigger-migrate-admin-btn").click

      expect(page).to have_content("Cannot run migration with out of date mirrors")

      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(tx_update_migration_mirror_synced: true)
      # rubocop:enable Rails/SkipsModelValidations

      find(".confirm-mirror-synced-btn").click

      expect(page).not_to have_content("Your local RMT/SMT mirror looks like it's out of sync.")
    end
    # rubocop:enable RSpec/ExampleLength
  end

  context "when the admin node has a migration and an update available" do
    before do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(
        tx_update_reboot_needed:           true,
        tx_update_migration_available:     true,
        tx_update_migration_mirror_synced: true,
        tx_update_migration_notes:         "https://release-notes-url",
        tx_update_migration_newversion:    "SUSE CaaS Platform 3.1 x86_64"
      )
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path
    end

    it "notices migration availability but does not let the user migrate" do
      expect(page).to have_content("Cluster has migration available. (Install Updates first)")
      expect(page).not_to have_content("MIGRATE ADMIN NODE")
    end
  end

  it "shows admin migration failed message" do
    # rubocop:disable Rails/SkipsModelValidations
    Minion.where(minion_id: "admin").update_all(tx_update_migration_available: true,
                                                tx_update_failed:              true)
    # rubocop:enable Rails/SkipsModelValidations
    visit authenticated_root_path

    expect(page).to have_content("An error occurred during the admin node migration process")
    expect(page).not_to have_content("MIGRATE ADMIN NODE")
  end
end
