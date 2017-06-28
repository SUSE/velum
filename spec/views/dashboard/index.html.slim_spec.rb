# frozen_string_literal: true
require "rails_helper"

describe "dashboard/index" do
  context "regular render" do
    it "has the url on the data-url attribute" do
      @unassigned_minions = []
      render

      section = assert_select(".nodes-container")
      expect(section.attribute("data-url").value).to eq authenticated_root_path
    end
  end
end

describe "dashboard/autoyast" do
  context "when proxy is enabled" do
    let(:http_proxy) { "squid.corp.net:3128"}
    let(:https_proxy) { "squid.corp.net:3443"}
    let(:no_proxy) { "localhost" }

    before do
      assign(:proxy_http, http_proxy)
      assign(:proxy_https, https_proxy)
      assign(:proxy_no_proxy, no_proxy)
      assign(:proxy_systemwide, true)
    end

    it "generates a proxy section" do
      render

      section = assert_select "profile/networking/proxy/http_proxy"
      expect(section.children.text).to eq(http_proxy)

      section = assert_select "profile/networking/proxy/https_proxy"
      expect(section.children.text).to eq(https_proxy)

      section = assert_select "profile/networking/proxy/no_proxy"
      expect(section.children.text).to eq(no_proxy)
    end
  end
end
