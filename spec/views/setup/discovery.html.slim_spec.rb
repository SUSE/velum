# frozen_string_literal: true
require "rails_helper"

describe "setup/discovery" do
  context "regular render" do
    it "has the url on the data-url attribute" do
      render

      section = assert_select(".nodes-container")
      expect(section.attribute("data-url").value).to eq setup_discovery_path
    end

    it "has a button to bootstrap the cluster" do
      render

      section = assert_select("input[type='submit']")
      text = section[0].attributes["value"].value
      expect(text).to eq "Bootstrap cluster"
    end
  end
end
