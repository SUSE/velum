require "rails_helper"

# rubocop:disable RSpec/AnyInstance, RSpec/ExampleLength
describe "feature: node removal", js: true do
  let!(:user) { create(:user) }
  let!(:minions) do
    Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion5.k8s.local" }]
  end

  before do
    setup_done
    login_as user, scope: :user
    stubbed = [
      [{ minions[2].minion_id => true }],
      [{ minions[2].minion_id => "" }]
    ]
    setup_stubbed_update_status!(stubbed: stubbed)
    setup_stubbed_pending_minions!(stubbed: [minions[3].minion_id])

    allow(Velum::Salt).to receive(:removal_orchestration)

    visit authenticated_root_path
  end

  it "shows 'Remove' link for each node" do
    expect(page).to have_link("Remove", count: Minion.assigned_role.count)
  end

  it "hides 'Remove' link if only 1 master and 1 worker" do
    Minion.destroy([minions[1].id, minions[2].id, minions[3].id])

    visit authenticated_root_path
    expect(page).not_to have_link("Remove")
  end

  context "with successful orchestration" do
    before do
      allow(Orchestration).to receive(:run).and_return(true)
    end

    it "changes 'Remove' link to 'Pending removal' on specific row" do
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_selector).click
      expect(page).to have_css(worker_selector, text: "Pending removal")
    end

    it "shows warning modal when invalid topology" do
      master_selector = ".remove-node-link[data-id='#{minions[0].minion_id}']"

      find(master_selector).click
      expect(page).to have_content("Invalid cluster topology")
    end

    it "proceeds with removal even after warning" do
      master_selector = ".remove-node-link[data-id='#{minions[0].minion_id}']"

      find(master_selector).click
      expect(page).to have_content("Proceed anyway")

      click_on "Proceed anyway"
      expect(page).to have_css(master_selector, text: "Pending removal")
    end

    it "disables other orchestration triggers" do
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      find(worker_selector).click
      minions[1].update!(highstate: "pending_removal")
      expect(page).to have_css(worker_selector, text: "Pending removal")

      # remove other nodes
      expect(page).to have_css(".remove-node-link.disabled", count: Minion.assigned_role.count)

      # assign nodes
      expect(page).to have_css(".assign-nodes-link.disabled")

      # update all nodes
      expect(page).to have_css("#update-all-nodes.hidden", visible: false)

      # update admin node
      expect(page).to have_css(".admin-outdated-notification.hidden", visible: false)
    end

    it "enable orchestration triggers after complete removal" do
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      find(worker_selector).click
      minions[1].update!(highstate: "pending_removal")
      expect(page).to have_css(worker_selector, text: "Pending removal")

      # removing
      expect(page).to have_css(".remove-node-link.disabled")

      # removed
      minions[1].destroy
      expect(page).not_to have_css(".remove-node-link.disabled")

      # assign nodes
      expect(page).not_to have_css(".assign-nodes-link.disabled")

      # update all nodes
      expect(page).not_to have_css("#update-all-nodes.hidden", visible: false)
    end

    it "enable orchestration triggers after complete removal (admin update)" do
      stubbed = [
        [{ "admin" => true, minions[2].minion_id => true }],
        [{ "admin" => "", minions[2].minion_id => "" }]
      ]
      setup_stubbed_update_status!(stubbed: stubbed)

      visit authenticated_root_path
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      find(worker_selector).click
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
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_selector).click
      expect(page).to have_content("Orchestration currently ongoing. Please wait for it to finish.")
    end
  end

  context "with failed orchestration" do
    it "shows that removal failed if something goes wrong" do
      allow(Orchestration).to receive(:run).and_return(true)
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_selector).click
      minions[1].update!(highstate: "removal_failed")
      expect(page).to have_content("Removal Failed")
    end

    it "shows that attempt failed if en exception happens during request" do
      # fake error just to mimic general exception withotu triggering capybara raise error
      allow_any_instance_of(MinionsController).to receive(:fetch_minion)
        .and_raise(ActiveRecord::RecordNotFound)
      worker_selector = ".remove-node-link[data-id='#{minions[3].minion_id}']"

      expect(page).to have_css(worker_selector, text: "Remove")
      find(worker_selector).click
      expect(page).to have_content("An attempt to remove node #{minions[3].minion_id} has failed")
    end
  end
end
# rubocop:enable RSpec/AnyInstance, RSpec/ExampleLength
