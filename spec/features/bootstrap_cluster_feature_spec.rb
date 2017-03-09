# frozen_string_literal: true
require "rails_helper"

feature "Bootstrap cluster feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    visit setup_discovery_path
  end

  scenario "It shows the minions as soon as they register", js: true do
    expect(page).not_to have_content("minion0.k8s.local")
    Minion.create!(hostname: "minion0.k8s.local")
    using_wait_time 10 do
      expect(page).to have_content("minion0.k8s.local")
    end
  end
end
