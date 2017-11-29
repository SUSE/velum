require "rails_helper"

describe "setup/discovery" do
  context "with a regular render" do
    it "has the url on the data-url attribute" do
      render

      section = assert_select(".nodes-container")
      expect(section.attribute("data-url").value).to eq setup_discovery_path
    end

    it "has a button to go to the next step" do
      render

      section = assert_select("input[type='submit']")
      text = section[0].attributes["value"].value
      expect(text).to eq "Next"
    end
  end
end
