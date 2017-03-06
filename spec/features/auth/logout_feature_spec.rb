# frozen_string_literal: true
require "rails_helper"

feature "Logout feature" do
  let!(:user) { create(:user) }

  before do
    login user
  end

  scenario "Redirects to login screen" do
    click_link("Logout")
    expect(current_url).to eq root_url
  end

  scenario "After login guest redirects to login page when he attempts to access dashboard again" do
    click_link("Logout")
    visit root_url
    expect(page).to have_content("Log in")
  end
end
