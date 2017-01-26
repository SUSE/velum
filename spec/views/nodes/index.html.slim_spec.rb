# frozen_string_literal: true
require "rails_helper"

describe "nodes/index" do
  context "regular render" do
    it "has the url on the data-url attribute" do
      render

      section = assert_select("#nodes")
      expect(section.attribute("data-url").value).to eq nodes_path
    end

    it "has a button to bootstrap the cluster" do
      render

      section = assert_select("#bootstrap-cluster")
      l = link?(section[0], bootstrap_nodes_path, "Bootstrap cluster")
      expect(l).to be_truthy
    end

    it "polls for minions" do
      render

      script = assert_select("script").children.text
      expect(script.strip).to eq "MinionPoller.poll();"
    end
  end
end
