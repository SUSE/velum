require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#user_image_tag" do
    let(:user) { create(:user, email: "user@example.com") }

    # Mocking the gravatar_image_tag
    def gravatar_image_tag(email)
      email
    end

    it "uses the gravatar image tag if enabled" do
      expect(user_image_tag(user)).to eq "user@example.com"
    end

    it "uses the fa icon if the given user was nil" do
      expect(user_image_tag(nil)).to be_nil
    end
  end
end
