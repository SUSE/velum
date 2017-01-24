# frozen_string_literal: true
require "rails_helper"

describe "devise/sessions/new" do
  before do
    # A trick to make devise-views think they have some essential methods when
    # they really don't in these tests.
    view.extend DeviseMock
  end

  it "contains the Log in string" do
    render

    section = assert_select("h2")
    expect(section.text.strip).to eq "Log in"
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

  it "has a Sign up link" do
    render

    # section[n]: 0 -> Log in; 1 -> Sign up
    section = assert_select("a")
    expect(link?(section[1], new_user_registration_path, "Sign up")).to be_truthy
  end

  it "will submit to the proper path" do
    render

    section = assert_select("#new_user")
    expect(form_request(section, :post, new_user_session_path)).to be_truthy
  end
end
