# frozen_string_literal: true
require "rails_helper"

describe "updates/index" do
  it "displays the page properly" do
    render

    section = assert_select("h1")
    expect(section.text).to eq "Updates#index"
  end
end
