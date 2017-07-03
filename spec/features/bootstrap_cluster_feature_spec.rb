# frozen_string_literal: true
require "rails_helper"

# rubocop:disable RSpec/AnyInstance
feature "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    setup_stubbed_update_status!
    setup_stubbed_pending_minions!
    visit setup_discovery_path
  end

  # rubocop:disable RSpec/ExampleLength
  context "Nodes bootstraping" do
    let!(:minions) do
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local" }]
    end

    before do
      # mock salt methods
      [:worker, :master].each do |role|
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
          .and_return(role)
      end
      allow(Velum::Salt).to receive(:orchestrate)
    end

    scenario "An user sees warning modal when trying to bootstrap 2 nodes", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select node minion1.k8s.local
        find("#roles_minion_#{minions[1].id}").click
      end

      click_on_when_enabled "#bootstrap"

      # means it didn't go to the overview page
      expect(page).not_to have_content("Summary")
      expect(page).to have_content("Cluster is too small")
    end

    scenario "An user bootstraps anyway a cluster with only 2 minions", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select node minion1.k8s.local
        find("#roles_minion_#{minions[1].id}").click
      end

      click_on_when_enabled "#bootstrap"

      # waits modal to appear
      expect(page).to have_content("Cluster is too small")

      click_button "Proceed anyway"

      using_wait_time 10 do
        # means it went to the overview page
        expect(page).to have_content("Summary")
        expect(page).to have_content(minions[0].fqdn)
        expect(page).to have_content(minions[1].fqdn)
        expect(page).not_to have_content(minions[2].fqdn)
        expect(page).not_to have_content(minions[3].fqdn)
      end
    end

    scenario "An user selects a subset of nodes to be bootstraped", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select node minion1.k8s.local
        find("#roles_minion_#{minions[1].id}").click
        # select node minion2.k8s.local
        find("#roles_minion_#{minions[2].id}").click
      end

      click_on_when_enabled "#bootstrap"

      using_wait_time 10 do
        # means it went to the overview page
        expect(page).to have_content("Summary")
        expect(page).to have_content(minions[0].fqdn)
        expect(page).to have_content(minions[1].fqdn)
        expect(page).to have_content(minions[2].fqdn)
        expect(page).not_to have_content(minions[3].fqdn)
      end
    end

    scenario "An user check all nodes at once to be bootstraped", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select all nodes
        find(".check-all").click
      end

      click_on_when_enabled "#bootstrap"

      using_wait_time 10 do
        expect(page).to have_content("Summary")
        expect(page).to have_content(minions[0].fqdn)
        expect(page).to have_content(minions[1].fqdn)
        expect(page).to have_content(minions[2].fqdn)
        expect(page).to have_content(minions[3].fqdn)
      end
    end
  end

  scenario "It shows the minions as soon as they register", js: true do
    expect(page).to have_content("No nodes found")
    expect(page).not_to have_content("minion0.k8s.local")

    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local")
    using_wait_time 10 do
      expect(page).not_to have_content("No nodes found")
      expect(page).to have_content("minion0.k8s.local")
    end
  end
  # rubocop:enable RSpec/ExampleLength

  scenario "An user sees 'No nodes found'", js: true do
    expect(page).to have_content("No nodes found")
    # bootstrap cluster button disabled
    expect(page).to have_button(value: "Bootstrap cluster", disabled: true)
  end
end
# rubocop:enable RSpec/AnyInstance
