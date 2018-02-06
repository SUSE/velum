require "rails_helper"

describe "Feature: login dialog" do
  let!(:user) { create(:user) }

  before do
    visit new_user_session_path
  end

  it "does not show any flash when accessing for the first time" do
    visit root_path
    expect(page).not_to have_content("You need to sign in or sign up before continuing.")
  end

  it "allows a existing user to login into velum with valid credentials" do
    # We don't use Capybara's `login_as` method on purpose, because we are
    # testing the UI for logging in.
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button("Log in")

    expect(page).to have_content("Configuration")
  end

  it "shows an error message when using invalid credentials" do
    # pending("fix the validations")
    fill_in "user_email", with: "foo"
    fill_in "user_password", with: "bar"
    click_button("Log in")

    expect(page).to have_content("Invalid Email or password")
  end

  it "redirects to the login plage when a guest tries to access dashboard" do
    visit root_path
    expect(page).to have_content("Log in")
  end

  it "redirects to the login page when trying to access a protected page" do
    visit setup_path
    expect(page).to have_content("You need to sign in or sign up before continuing.")
  end

  it "redirects back to a protected page after successful login" do
    visit setup_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button("Log in")

    expect(page).to have_current_path(setup_path)
  end
end
