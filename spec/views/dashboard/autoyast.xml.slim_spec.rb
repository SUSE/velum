require "rails_helper"

describe "dashboard/autoyast" do
  context "when proxy is enabled" do
    before do
      assign(:proxy_systemwide, true)
    end

    it "generates a post partitioning script" do
      render

      matches = assert_select("scripts/chroot-scripts/script")
      expect(matches.find { |m| m.to_s.include?("set_proxy.sh") }).not_to be_nil
    end
  end

  context "when proxy is not enabled" do
    before do
      assign(:proxy_systemwide, false)
    end

    it "does not generate a proxy script" do
      render

      matches = assert_select("scripts/chroot-scripts/script")
      expect(matches.find { |m| m.to_s.include?("set_proxy.sh") }).to be_nil
    end

  end

end
