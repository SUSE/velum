require "rails_helper"

# rubocop:disable RSpec/ExampleLength
describe "Feature: Admission webhook", js: true do
  let!(:user) { create(:user) }

  before do
    setup_done
    login_as user, scope: :user
  end

  describe "#index" do
    before do
      visit settings_admission_webhook_index_path
    end

    it "enables the feature" do
      expect(page).to have_css(".enable-admission-webhook-btn-group .enable")

      find(".enable-admission-webhook-btn-group .enable").click
      expect(page).to have_content("Client certificate used")

      attach_file("admission_webhook_cert_file", Rails.root.join("spec", "fixtures", "admin.crt"))
      attach_file("admission_webhook_key_file", Rails.root.join("spec", "fixtures", "admin.key"))

      click_on("Save")
      expect(page).to have_content("Admission webhook settings successfully saved.")
    end

    it "shows validation error" do
      expect(page).to have_css(".enable-admission-webhook-btn-group .enable")

      find(".enable-admission-webhook-btn-group .enable").click
      expect(page).to have_content("Client certificate used")

      attach_file("admission_webhook_cert_file", Rails.root.join("spec", "fixtures", "empty.txt"))
      attach_file("admission_webhook_key_file", Rails.root.join("spec", "fixtures", "empty.txt"))

      click_on("Save")
      expect(page).to have_content("Certificate can't be an empty file")
      expect(page).to have_content("Key can't be an empty file")
    end

    context "when there's data stored" do
      before do
        pillars = {
          api_admission_webhook_enabled: "true",
          api_admission_webhook_cert:    "cert",
          api_admission_webhook_key:     "key"
        }
        Pillar.apply(pillars, unprotected_pillars: pillars.keys)

        visit settings_admission_webhook_index_path
      end

      it "shows a modal warning when trying to disable" do
        expect(page).to have_css(".enable-admission-webhook-btn-group .disable")

        find(".enable-admission-webhook-btn-group .disable").click
        click_on("Save")

        expect(page).to have_content("Please confirm")
        expect(page).to have_button("Proceed anyway")
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
