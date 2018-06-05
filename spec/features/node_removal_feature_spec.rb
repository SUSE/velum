require "rails_helper"

# rubocop:disable RSpec/AnyInstance, RSpec/ExampleLength
describe "feature: node removal", js: true do
  let!(:user) { create(:user) }
  let!(:minions) do
    Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local", role: "master",
                      tx_update_reboot_needed: true },
                    { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion5.k8s.local" }]
  end

  before do
    setup_done
    login_as user, scope: :user
    setup_stubbed_pending_minions!(stubbed: [minions[3].minion_id])

    allow(Orchestration).to receive(:run).and_return(true)

    visit authenticated_root_path
  end

  it "shows 'Remove' link for each node" do
    expect(page).to have_link("Remove", count: Minion.cluster_role.count)
  end

  it "hides 'Remove' link if 2 remaining and 1 is failed" do
    [minions[1], minions[2], minions[3]].each { |m| m.update(highstate: :removal_failed) }

    visit authenticated_root_path
    expect(page).not_to have_link("Remove")
  end

  it "hides 'Remove' link if only 1 master and 1 worker" do
    Minion.destroy([minions[1].id, minions[2].id, minions[3].id])

    visit authenticated_root_path
    expect(page).not_to have_link("Remove")
  end

  it "does not show warning modal when removing worker and # masters is even" do
    # removed one master to put cluster in unsupported configuration
    minions[0].destroy

    visit authenticated_root_path
    worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
    worker_link = "#{worker_selector} .remove-node-link"

    find(worker_link).click
    expect(page).to have_css(worker_selector, text: "Pending removal")
    expect(page).not_to have_content("Invalid cluster topology")
  end

  context "with successful orchestration" do
    it "changes 'Remove' link to 'Pending removal' on specific row" do
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_link).click
      expect(page).to have_css(worker_selector, text: "Pending removal")
    end

    it "shows warning modal when invalid topology" do
      master_selector = ".actions-column[data-id='#{minions[0].minion_id}']"
      master_link = "#{master_selector} .remove-node-link"

      find(master_link).click
      expect(page).to have_content("Unsupported cluster topology")
    end

    it "proceeds with removal even after warning" do
      master_selector = ".actions-column[data-id='#{minions[0].minion_id}']"
      master_link = "#{master_selector} .remove-node-link"

      find(master_link).click
      expect(page).to have_content("Proceed anyway")

      click_on "Proceed anyway"
      expect(page).to have_css(master_selector, text: "Pending removal")
    end

    it "disables other orchestration triggers" do
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      find(worker_link).click
      minions[1].update!(highstate: "pending_removal")
      expect(page).to have_css(worker_selector, text: "Pending removal")

      # remove other nodes
      expect(page).to have_css(".remove-node-link.disabled", count: Minion.cluster_role.count - 1)

      # assign nodes
      expect(page).not_to have_link("(new)")

      # update all nodes
      expect(page).to have_css("#update-all-nodes.hidden", visible: false)

      # update admin node
      expect(page).to have_css(".admin-outdated-notification.hidden", visible: false)
    end

    it "enable orchestration triggers after complete removal" do
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      find(worker_link).click
      minions[1].update!(highstate: "pending_removal")
      expect(page).to have_css(worker_selector, text: "Pending removal")

      # removing
      expect(page).to have_css(".remove-node-link.disabled")

      # removed
      minions[1].destroy
      expect(page).not_to have_css(".remove-node-link.disabled")

      # assign nodes
      expect(page).to have_link("(new)")

      # update all nodes
      expect(page).not_to have_css("#update-all-nodes.hidden", visible: false)
    end

    it "enable orchestration triggers after complete removal (admin update)" do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                  tx_update_failed:        false)
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      find(worker_link).click
      minions[1].update!(highstate: "pending_removal")
      expect(page).to have_css(worker_selector, text: "Pending removal")

      # removing
      expect(page).to have_css(".remove-node-link.disabled")

      # removed
      minions[1].destroy
      expect(page).not_to have_css(".remove-node-link.disabled")

      # assign nodes
      expect(page).not_to have_css(".assign-nodes-link.disabled")

      # update admin node
      expect(page).not_to have_css(".admin-outdated-notification.hidden", visible: false)
    end
  end

  context "when ongoing orchestration" do
    before do
      allow(Orchestration).to receive(:run).and_raise(Orchestration::OrchestrationOngoing)
    end

    it "shows alert message that there's already an ongoing orchestration" do
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_link).click
      expect(page).to have_content("Orchestration currently ongoing. Please wait for it to finish.")
    end
  end

  context "with failed orchestration" do
    it "shows that removal failed if something goes wrong" do
      allow(Orchestration).to receive(:run).and_return(true)
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_link).click
      minions[1].update!(highstate: "removal_failed")
      expect(page).to have_content("Removal Failed")
      expect(page).to have_link("Force remove")
    end

    it "shows that attempt failed if en exception happens during request" do
      # fake error just to mimic general exception withotu triggering capybara raise error
      allow_any_instance_of(MinionsController).to receive(:fetch_minion)
        .and_raise(ActiveRecord::RecordNotFound)
      worker_selector = ".actions-column[data-id='#{minions[3].minion_id}']"
      worker_link = "#{worker_selector} .remove-node-link"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_link).click
      expect(page).to have_content("An attempt to remove node #{minions[3].minion_id} has failed")
    end
  end
end
# rubocop:enable RSpec/AnyInstance, RSpec/ExampleLength
