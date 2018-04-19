require "rails_helper"

# rubocop:disable RSpec/AnyInstance
describe "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    setup_stubbed_pending_minions!
    visit setup_discovery_path
  end

  # rubocop:disable RSpec/ExampleLength
  context "when nodes are bootstrapping" do
    let!(:minions) do
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local" }]
    end

    before do
      allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).and_return(true)
      allow(Orchestration).to receive(:run)
    end

    it "A user sees warning modal when trying to bootstrap 2 nodes", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      # means it didn't go to the overview page
      expect(page).not_to have_content("Summary")
      expect(page).to have_content("Cluster is too small")
    end

    it "A user bootstraps anyway a cluster with only 2 minions", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      # waits modal to appear
      expect(page).to have_content("Cluster is too small")

      click_button "Proceed anyway"

      # means it went to the confirmation page
      expect(page).to have_content("Confirm bootstrap")
      fill_in("External Kubernetes API FQDN", with: "some.url")
      fill_in("External Dashboard FQDN", with: "some.url")
      click_on_when_enabled "#bootstrap"

      # means it went to the overview page
      expect(page).to have_content("Summary")
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).not_to have_content(minions[2].fqdn)
      expect(page).not_to have_content(minions[3].fqdn)
    end

    it "A user set roles, go next, then back and can still accept new nodes", js: true do
      setup_stubbed_pending_minions!(stubbed: [minions[3].minion_id])

      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .worker-btn").click
      # select node minion2.k8s.local
      find(".minion_#{minions[2].id} .worker-btn").click

      expect(page).to have_content(minions[3].minion_id)
      expect(page).to have_content("Accept Node")

      click_on_when_enabled "#set-roles"

      # means it went to the confirmation page
      expect(page).to have_content("Confirm bootstrap")
      click_on "Back"

      # means it went back to discovery page
      expect(page).to have_content("Select nodes and roles")
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).to have_content(minions[2].fqdn)

      # means it can accept pending node
      expect(page).to have_content(minions[3].minion_id)
      expect(page).to have_content("Accept Node")
    end

    it "A user selects a subset of nodes to be bootstrapped", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .worker-btn").click
      # select node minion2.k8s.local
      find(".minion_#{minions[2].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      # means it went to the confirmation page
      expect(page).to have_content("Confirm bootstrap")
      fill_in("External Kubernetes API FQDN", with: "some.url")
      fill_in("External Dashboard FQDN", with: "some.url")
      click_on_when_enabled "#bootstrap"

      # means it went to the overview page
      expect(page).to have_content("Summary")
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).to have_content(minions[2].fqdn)
      expect(page).not_to have_content(minions[3].fqdn)
    end

    it "A user check all nodes at once to be bootstrapped", js: true do
      # wait for all minions to be there
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).to have_content(minions[2].fqdn)
      expect(page).to have_content(minions[3].fqdn)
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select all nodes
      find(".select-nodes-btn").click

      click_on_when_enabled "#set-roles"

      # means it went to the confirmation page
      expect(page).to have_content("Confirm bootstrap")
      fill_in("External Kubernetes API FQDN", with: "some.url")
      fill_in("External Dashboard FQDN", with: "some.url")
      click_on_when_enabled "#bootstrap"

      expect(page).to have_content("Summary")
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).to have_content(minions[2].fqdn)
      expect(page).to have_content(minions[3].fqdn)
    end

    it "A user selects a multiple master configuration to be bootstrapped", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .master-btn").click
      # select node minion2.k8s.local
      find(".minion_#{minions[2].id} .master-btn").click
      # select node minion3.k8s.local
      find(".minion_#{minions[3].id} .worker-btn").click
      # select node minion4.k8s.local
      find(".minion_#{minions[4].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      # means it went to the confirmation page
      expect(page).to have_content("Confirm bootstrap")
      fill_in("External Kubernetes API FQDN", with: "some.url")
      fill_in("External Dashboard FQDN", with: "some.url")
      click_on_when_enabled "#bootstrap"

      # means it went to the overview page
      expect(page).to have_content("Summary")
      expect(page).to have_content(minions[0].fqdn)
      expect(page).to have_content(minions[1].fqdn)
      expect(page).to have_content(minions[2].fqdn)
      expect(page).to have_content(minions[3].fqdn)
      expect(page).to have_content(minions[4].fqdn)
    end

    it "A user cannot bootstrap nodes with conflicting hostnames", js: true do
      duplicated = Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion99.k8s.local" },
                                   { minion_id: SecureRandom.hex, fqdn: "minion99.k8s.local" }]
      # select nodes minion99.k8s.local
      find(".minion_#{duplicated[0].id} .worker-btn").click
      find(".minion_#{duplicated[1].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      expect(page).to have_content("All nodes must have unique hostnames")
      expect(page).to have_button(value: "Next", disabled: true)
    end

    it "A user cannot bootstrap nodes with conflicting hostnames [2]", js: true do
      duplicated = Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "Minion99.k8s.local" },
                                   { minion_id: SecureRandom.hex, fqdn: "minion99.k8s.local" }]
      # select nodes minion99.k8s.local
      find(".minion_#{duplicated[0].id} .worker-btn").click
      find(".minion_#{duplicated[1].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      expect(page).to have_content("All nodes must have unique hostnames")
      expect(page).to have_button(value: "Next", disabled: true)
    end

    it "A user cannot bootstrap an even multiple master configuration", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click
      # select node minion1.k8s.local
      find(".minion_#{minions[1].id} .master-btn").click
      # select node minion2.k8s.local
      find(".minion_#{minions[2].id} .worker-btn").click
      # select node minion3.k8s.local
      find(".minion_#{minions[3].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      expect(page).to have_content("The number of masters has to be an odd number")
      expect(page).to have_button(value: "Next", disabled: true)
    end

    it "A user cannot bootstap if no worker is selected", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .master-btn").click

      click_on_when_enabled "#set-roles"

      expect(page).to have_content("You haven't selected one worker at least")
      expect(page).to have_button(value: "Next", disabled: true)
    end

    it "A user cannot bootstap if no master is selected", js: true do
      # select master minion0.k8s.local
      find(".minion_#{minions[0].id} .worker-btn").click

      click_on_when_enabled "#set-roles"

      expect(page).to have_content("You haven't selected one master at least")
      expect(page).to have_button(value: "Next", disabled: true)
    end
  end

  it "shows the minions as soon as they register", js: true do
    expect(page).to have_content("No nodes found")
    expect(page).not_to have_content("minion0.k8s.local")

    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local")
    expect(page).not_to have_content("No nodes found")
    expect(page).to have_content("minion0.k8s.local")
  end
  # rubocop:enable RSpec/ExampleLength

  it "A user sees 'No nodes found'", js: true do
    expect(page).to have_content("No nodes found")
    # bootstrap cluster button disabled
    expect(page).to have_button(value: "Next", disabled: true)
  end
end
# rubocop:enable RSpec/AnyInstance
