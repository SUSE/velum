require "rails_helper"

describe "Bootstrap settings feature" do
  let!(:user) { create(:user) }

  before do
    login_as user, scope: :user
    visit setup_path
  end

  it "toggles the panel form", js: true do
    expect(page).not_to have_css(".suse-mirror-panel-body.in")

    find(".enable-suse-registry-mirror").click
    expect(page).to have_css(".suse-mirror-panel-body.in")

    find(".disable-suse-registry-mirror").click
    expect(page).not_to have_css(".suse-mirror-panel-body.in")
  end

  context "when suse mirror registry is enabled", js: true do
    before do
      find(".enable-suse-registry-mirror").click
    end

    it "shows warning if url is insecure" do
      fill_in "URL", with: "http://insecure.local"
      expect(page).to have_content("You are using an insecure mirror address")
    end

    it "shows error if url is invalid" do
      fill_in "URL", with: "htt://insecure.local"
      expect(page).to have_content("This is not a valid URL")
    end

    it "shows error if url is invalid [2]" do
      fill_in "URL", with: "insecure.local"
      expect(page).to have_content("This is not a valid URL")
    end

    it "toggles certificate textarea" do
      expect(page).to have_css("#settings_suse_registry_mirror_certificate", visible: false)

      find(".enable-mirror-certificate").click
      expect(page).to have_css("#settings_suse_registry_mirror_certificate")

      find(".disable-mirror-certificate").click
      expect(page).to have_css("#settings_suse_registry_mirror_certificate", visible: false)
    end
  end

  context "CPI configuration", js: true do
    it "shows panel settings" do
      expect(page).to have_content("Cloud provider integration")
    end

    it "shows custom settings for openstack" do
      find(".enable-cpi").click
      expect(page).to have_css(".cloud-settings-panel-body.in")
      expect(page).to have_content("Keystone API URL")
    end

    it "attaches openstack value when no cloud framework is set" do
      expect(page).to have_css("input[value=openstack]")
    end

    context "when cloud framework is set" do
      it "attaches ec2 value when AWS" do
        Pillar.create(pillar: "cloud:framework", value: "ec2")

        visit setup_path
        expect(page).to have_css("input[value=ec2]")
      end

      it "shows GCE option when gce" do
        Pillar.create(pillar: "cloud:framework", value: "gce")

        visit setup_path
        expect(page).to have_css("input[value=gce]")
      end

      it "shows Azure option when azure" do
        Pillar.create(pillar: "cloud:framework", value: "azure")

        visit setup_path
        expect(page).to have_css("input[value=azure]")
      end
    end
  end
end
