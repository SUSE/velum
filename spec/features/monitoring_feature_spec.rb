require "rails_helper"

describe "Monitoring feature" do
  let!(:user) { create(:user) }

  before do
    setup_done
    login_as user, scope: :user
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
    setup_stubbed_pending_minions!
    visit authenticated_root_path
  end

  it "updates the status of the minions automatically", js: true do
    # We poll every 5 seconds so the default Capybara wait time might not be enough
    expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-circle-o")
    Minion.second.update!(highstate: "pending")
    expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-refresh")
  end

  # rubocop:disable RSpec/ExampleLength
  it "shows the number of new minions", js: true do
    unassigned_count = find(".unassigned-count")
    expect(page).not_to have_content("minion1.k8s.local")
    expect(unassigned_count).to have_content("0")

    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: nil)

    expect(unassigned_count).to have_content("1")
    expect(page).not_to have_content("minion1.k8s.local")
  end
  # rubocop:enable RSpec/ExampleLength

  it "shows the node as offline", js: true do
    Minion.last.update!(online: false)

    expect(page).to have_css(".fa-circle.text-danger")
  end
end
