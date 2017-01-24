# frozen_string_literal: true
require "rails_helper"

describe "admin/index" do
  it "contains the 'Admin#index' string" do
    render

    section = assert_select("h1")
    expect(section.text.strip).to eq "Admin#index"
  end
end
