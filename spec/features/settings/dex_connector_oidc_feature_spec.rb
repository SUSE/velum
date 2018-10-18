require "rails_helper"

# rubocop:disable RSpec/ExampleLength
describe "Feature: OIDC connector settings", js: true do
  let!(:user)                { create(:user) }
  let!(:dex_connector_oidc)  { create(:dex_connector_oidc, :skip_validation) }
  let!(:dex_connector_oidc2) { create(:dex_connector_oidc, :skip_validation) }
  let!(:dex_connector_oidc3) { create(:dex_connector_oidc, :skip_validation) }

  before do
    setup_done
    login_as user, scope: :user
  end

  describe "#index" do
    before do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        visit settings_dex_connector_oidcs_path
      end
    end

    it "allows a user to delete an oidc connector" do
      expect(page).to have_content(dex_connector_oidc.name)
      accept_alert do
        find(".dex_connector_oidc#{dex_connector_oidc.id} .delete-btn").click
      end

      expect(page).to have_content("OIDC Connector was successfully removed.")
      expect(page).not_to have_content(dex_connector_oidc.name)
    end

    it "allows a user to go to an oidc connector's details page" do
      click_link(dex_connector_oidc.name)

      expect(page).to have_current_path(settings_dex_connector_oidc_path(dex_connector_oidc))
    end

    it "allows a user to go to an oidc connector's edit page" do
      find(".dex_connector_oidc#{dex_connector_oidc.id} .edit-btn").click

      expect(page).to have_current_path(edit_settings_dex_connector_oidc_path(dex_connector_oidc))
    end

    it "allows a user to go to the new oidc connector page" do
      click_link("Add OIDC connector")

      expect(page).to have_current_path(new_settings_dex_connector_oidc_path)
    end

    it "lists all the oidc connectors" do
      expect(page).to have_content(dex_connector_oidc.name)
      expect(page).to have_content(dex_connector_oidc2.name)
      expect(page).to have_content(dex_connector_oidc3.name)
    end
  end

  describe "#new" do
    before do
      visit new_settings_dex_connector_oidc_path
    end

    it "allows a user to create an OIDC connector" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        fill_in id: "oidc_name",          with: "test oidc"
        fill_in id: "oidc_provider",      with: "http://your.fqdn.here:5556/dex"
        fill_in id: "oidc_client_id",     with: "client"
        fill_in id: "oidc_client_secret", with: "secret_string"

        click_button("Test Connection")
        click_button("Save")
        expect(page).to have_content("OIDC Connector was successfully created.")
        expect(page).to have_current_path(settings_dex_connector_oidcs_path)
      end
    end
  end

  describe "#edit" do
    before do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        visit edit_settings_dex_connector_oidc_path(dex_connector_oidc)
      end
    end

    it "allows a user to edit an oidc connector clicking validate and then save" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        fill_in id: "oidc_name", with: "a new name"

        click_button("Test Connection")
        click_button("Save")
        expect(page).to have_content("OIDC Connector was successfully updated.")
      end
    end
  end

  describe "#show" do
    before do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        visit settings_dex_connector_oidc_path(dex_connector_oidc)
      end
    end

    it "allows a user to delete an oidc connector" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        accept_alert do
          click_on("Delete")

          expect(page).not_to have_content(dex_connector_oidc.name)
          expect(page).to have_content("OIDC Connector was successfully removed.")
          expect(page).to have_current_path(settings_dex_connector_oidcs_path)
        end
      end
    end

    it "allows a user to go to an oidc connector's edit page" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        click_on("Edit")

        expect(page).to have_current_path(edit_settings_dex_connector_oidc_path(dex_connector_oidc))
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
