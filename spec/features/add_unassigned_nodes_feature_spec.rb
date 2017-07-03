# frozen_string_literal: true
require "rails_helper"

# rubocop:disable RSpec/AnyInstance
feature "Add unassigned nodes" do
  let!(:user) { create(:user) }
  let!(:minions) do
    Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local" },
                    { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local" }]
  end

  before do
    login_as user, scope: :user
    setup_stubbed_update_status!
    setup_stubbed_pending_minions!

    [:worker, :master].each do |role|
      allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
        .and_return(role)
    end
    allow(Velum::Salt).to receive(:orchestrate)

    visit assign_nodes_path
  end

  scenario "An user sees (new) link", js: true do
    visit authenticated_root_path

    expect(page).to have_content("(new)")
  end

  scenario "An user selects which nodes will be added", js: true do

    # select node minion3.k8s.local
    find("#roles_minion_#{minions[2].id}", match: :first).click

    click_button "Add nodes"
    expect(page).to have_content(minions[2].fqdn).and have_no_content(minions[3].fqdn)
  end

  scenario "An user check all nodes at once to be added", js: true do
    # select all nodes
    find(".check-all", match: :first).click

    click_button "Add nodes"
    expect(page).to have_content(minions[2].fqdn).and have_content(minions[3].fqdn)
  end

  scenario "It shows the nodes as soon as they register", js: true do
    expect(page).not_to have_content("minion4.k8s.local")
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local")
    expect(page).to have_content("minion4.k8s.local")
  end
end
# rubocop:enable RSpec/AnyInstance
