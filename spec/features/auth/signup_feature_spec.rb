# frozen_string_literal: true
require "rails_helper"

feature "Signup feature" do
  let(:user) { build(:user) }

  # rubocop:disable RSpec/ExampleLength

  # XXX: the following tests depend on another and thus cannot be split into
  # multiple scenarios. This must be fixed as soon as multiuser support is
  # implemented.

  scenario "Account creation tests", js: true do
    # account creation reachable
    visit new_user_session_path
    click_link("Create an account")
    expect(page).to have_current_path(new_user_registration_path)

    # wrong email format
    fill_in "user_email", with: "gibberish@asdasd"
    expect(page).to have_content("Warning: it's preferred to \
      use an email address in the format \"user@example.com\"")

    # password confirmation doesn't match Password
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "12341234"
    fill_in "user_password_confirmation", with: "532"
    click_button("Create Admin")
    expect(page).to have_content("Password confirmation doesn't match Password")

    # successful account creation
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    fill_in "user_password_confirmation", with: user.password
    click_button("Create Admin")
    expect(page).to have_content("You have signed up successfully")
    click_link("Logout")

    # `Create an account` button will not be displayed anymore as only one user
    # is currently supported
    visit new_user_session_path
    expect(page).not_to have_content("Create an account")

    # forcefully visiting the registration path must redirect to the
    # root_path and yield an alert.
    visit new_user_registration_path
    expect(page).to have_current_path(root_path)
    expect(page).to have_content("Admin user already exists.")
  end
  # rubocop:enable RSpec/ExampleLength
end
