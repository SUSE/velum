require "rails_helper"

describe "dashboard/index" do
  context "with a regular render" do
    it "has the url on the data-url attribute" do
      @unassigned_minions = []
      render

      section = assert_select(".nodes-container")
      expect(section.attribute("data-url").value).to eq authenticated_root_path
    end
  end
end
