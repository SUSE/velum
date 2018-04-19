require "rails_helper"

# rubocop:disable RSpec/AnyInstance, RSpec/ExampleLength
describe "Add unassigned nodes", js: true do
  let!(:user) { create(:user) }
  let!(:minions) do
    Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                    { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker" },
                    { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local" },
                    { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local" }]
  end

  before do
    setup_done
    login_as user, scope: :user
    setup_stubbed_pending_minions!

    allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).and_return(true)
    allow(Orchestration).to receive(:run)

    visit assign_nodes_path
  end

  it "A user sees (new) link" do
    visit authenticated_root_path

    expect(page).to have_content("(new)")
  end

  it "A user selects which nodes will be added" do
    # select node minion3.k8s.local
    find(".minion_#{minions[2].id} .worker-btn").click

    click_button "Add nodes"
    expect(page).to have_content(minions[2].fqdn).and have_no_content(minions[3].fqdn)
  end

  it "A user cannot add nodes with conflicting hostnames" do
    minion = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local")

    # select duplicated node minion1.k8s.local
    find(".minion_#{minion.id} .worker-btn").click

    click_button "Add nodes"
    expect(page).to have_content("with conflicting hostnames")
    expect(page).to have_button(value: "Add nodes", disabled: true)
  end

  it "A user cannot add nodes with conflicting hostnames [2]" do
    minion = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local")

    # select duplicated new nodes minion2.k8s.local
    find(".minion_#{minion.id} .worker-btn").click
    find(".minion_#{minions[minions.length - 2].id} .worker-btn").click

    click_button "Add nodes"
    expect(page).to have_content("with conflicting hostnames")
    expect(page).to have_button(value: "Add nodes", disabled: true)
  end

  it "cannot add a number (even) of master nodes that breaks the odd constraint" do
    minion = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local")

    # select only one master node
    find(".minion_#{minion.id} .master-btn").click

    click_button "Add nodes"
    expect(page).to have_content("The number of masters to be added needs to maintain")
    expect(page).to have_button(value: "Add nodes", disabled: true)
  end

  it "cannot add a number (odd) of master nodes that breaks the odd constraint" do
    minion = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local")
    minion2 = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local")
    minion3 = Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local")

    # select only one master node
    find(".minion_#{minion.id} .master-btn").click
    find(".minion_#{minion2.id} .master-btn").click
    find(".minion_#{minion3.id} .master-btn").click

    click_button "Add nodes"
    expect(page).to have_content("The number of masters to be added needs to maintain")
    expect(page).to have_button(value: "Add nodes", disabled: true)
  end

  it "A user check all nodes at once to be added" do
    # wait for all minions to be there
    expect(page).to have_content(minions[2].fqdn)
    expect(page).to have_content(minions[3].fqdn)

    # select all nodes
    find(".select-nodes-btn").click

    click_button "Add nodes"
    expect(page).to have_content(minions[2].fqdn).and have_content(minions[3].fqdn)
  end

  it "shows the nodes as soon as they register" do
    expect(page).not_to have_content("minion4.k8s.local")
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion4.k8s.local")
    expect(page).to have_content("minion4.k8s.local")
  end
end
# rubocop:enable RSpec/AnyInstance, RSpec/ExampleLength
