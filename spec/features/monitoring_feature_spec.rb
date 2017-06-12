# frozen_string_literal: true
require "rails_helper"

feature "Monitoring feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
    setup_stubbed_update_status!
    visit authenticated_root_path
  end

  scenario "It updates the status of the minions automatically", js: true do
    # We poll every 5 seconds so the default Capybara wait time might not be enough
    using_wait_time 10 do
      expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-circle-o")
      Minion.first.update!(highstate: "pending")
      expect(page).to have_selector(".nodes-container tbody tr i.fa.fa-refresh")
    end
  end

  # rubocop:disable RSpec/ExampleLength
  # rubocop:disable RSpec/MultipleExpectations:
  scenario "It shows a message about new minions", js: true do
    using_wait_time 10 do
      expect(page).not_to have_content("minion1.k8s.local")
      expect(page).not_to have_content(
        "nodes are available but have not been added to the cluster yet"
      )
      Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: nil)

      expect(page).to have_content(
        "1 new nodes are available but have not been added to the cluster"
      )
      expect(page).not_to have_content("minion1.k8s.local")
    end
  end
  # rubocop:enable RSpec/ExampleLength
  # rubocop:enable RSpec/MultipleExpectations:
end
