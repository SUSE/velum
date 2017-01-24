# frozen_string_literal: true
require "rails_helper"

describe "devise/registrations/new" do
  before do
    # A trick to make devise-views think they have some essential methods when
    # they really don't in these tests.
    view.extend DeviseMock
  end

  it "the email input is really an HTML email one" do
    render

    section = assert_select("#user_email")
    expect(section.attribute("type").value).to eq("email")
  end

  it "the password input is legit" do
    render

    section = assert_select("#user_password")
    expect(section.attribute("type").value).to eq("password")
  end

  it "the password confirmation input is legit" do
    render

    section = assert_select("#user_password_confirmation")
    expect(section.attribute("type").value).to eq("password")
  end

  it "will submit to the proper path" do
    render

    section = assert_select("#new_user")
    expect(form_request(section, :post, user_registration_path)).to be_truthy
  end

  context "login link" do
    it "does not show the link if there's no user" do
      assign(:have_users, false)
      render

      assert_select("#sign-in", count: 0)
    end

    it "shows the link if there's a user already" do
      assign(:have_users, true)
      render

      section = assert_select("#sign-in")
      l = link?(section[0], new_user_session_path, "I already have an account. Login.")
      expect(l).to be_truthy
    end
  end
end
