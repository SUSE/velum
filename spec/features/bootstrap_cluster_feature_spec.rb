# frozen_string_literal: true
require "rails_helper"

# rubocop:disable RSpec/AnyInstance
feature "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    setup_stubbed_update_status!
    visit setup_discovery_path
  end

  # rubocop:disable RSpec/ExampleLength
  context "Nodes bootstraping" do
    let!(:minions) do
      Minion.create!([{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local" },
                      { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local" }])
    end

    before do
      # mock salt methods
      [:minion, :master].each do |role|
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
          .and_return(role)
      end
      allow(Velum::Salt).to receive(:orchestrate)
    end

    scenario "An user selects which nodes will be bootstraped", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select node minion1.k8s.local
        find("#roles_minion_#{minions[1].id}").click
      end

      click_button "Bootstrap cluster"
      using_wait_time 10 do
        expect do
          page.to have_content(minions[0].fqdn)
          page.to have_content(minions[1].fqdn)
          page.not_to have_content(minions[2].fqdn)
        end
      end
    end

    scenario "An user check all nodes at once to be bootstraped", js: true do
      using_wait_time 10 do
        # select master minion0.k8s.local
        find("#roles_master_#{minions[0].id}").click
        # select all nodes
        find(".check-all").click
      end

      click_button "Bootstrap cluster"
      using_wait_time 10 do
        expect do
          page.to have_content(minions[0].fqdn)
          page.to have_content(minions[1].fqdn)
          page.to have_content(minions[2].fqdn)
        end
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength

  scenario "It shows the minions as soon as they register", js: true do
    expect(page).not_to have_content("minion0.k8s.local")
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local")
    using_wait_time 10 do
      expect(page).to have_content("minion0.k8s.local")
    end
  end
end
# rubocop:enable RSpec/AnyInstance
