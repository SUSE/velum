require "rails_helper"

# rubocop:disable RSpec/ExampleLength
describe "Feature: Mirrors settings", js: true do
  let!(:user) { create(:user) }
  let!(:registry) { create(:registry) }
  let!(:registry2) { create(:registry) }
  let!(:mirror) { create(:registry_mirror, registry: registry) }
  let!(:mirror2) { create(:registry_mirror, registry: registry) }
  let!(:mirror3) { create(:registry_mirror, registry: registry2) }
  let(:admin_cert_text) { file_fixture("admin.crt").read.strip }

  before do
    setup_done
    login_as user, scope: :user
  end

  describe "#index" do
    before do
      visit settings_registry_mirrors_path
    end

    it "allows an user to delete a mirror" do
      expect(page).to have_content(mirror.name)
      accept_alert do
        find(".mirror_#{mirror.id} .delete-btn").click
      end

      expect(page).to have_content("Mirror was successfully removed.")
      expect(page).not_to have_content(mirror.name)
    end

    it "allows an user to go to a mirror's details page" do
      click_on(mirror.name)

      expect(page).to have_current_path(settings_registry_mirror_path(mirror))
    end

    it "allows an user to go to a mirror's edit page" do
      find(".mirror_#{mirror.id} .edit-btn").click

      expect(page).to have_current_path(edit_settings_registry_mirror_path(mirror))
    end

    it "allows an user to go to the new mirror page" do
      click_on("Add Mirror")

      expect(page).to have_current_path(new_settings_registry_mirror_path)
    end

    it "lists all the mirrors grouped by registries" do
      expect(page).to have_content(mirror.name)
      expect(page).to have_content(mirror2.name)
      expect(page).to have_content(mirror3.name)
    end
  end

  describe "#new" do
    before do
      visit new_settings_registry_mirror_path
    end

    it "allows an user to create a mirror (without certificate)" do
      select registry.name
      fill_in "Name", with: "Mirror"
      fill_in "URL", with: "http://google.com"
      click_button("Save")

      last_mirror = RegistryMirror.last
      expect(page).not_to have_content("Certificate")
      expect(page).to have_content("Mirror was successfully created.")
      expect(page).to have_current_path(settings_registry_mirror_path(last_mirror))
    end

    it "allows an user to create a mirror (w/ certificate)" do
      select registry.name
      fill_in "Name", with: "Mirror"
      fill_in "URL", with: "https://google.com"
      fill_in "Certificate", with: admin_cert_text
      click_button("Save")

      last_mirror = RegistryMirror.last
      expect(page).to have_content(admin_cert_text)
      expect(page).to have_content("Mirror was successfully created.")
      expect(page).to have_current_path(settings_registry_mirror_path(last_mirror))
    end

    it "allows an user to go to the new registry page if no registry selected" do
      click_on("Create new registry")

      expect(page).to have_current_path(new_settings_registry_path)
    end

    it "pre-selects registry when coming from registry" do
      visit settings_registry_path(registry)
      click_on("Add Mirror")

      expect(page).to have_current_path(new_settings_registry_mirror_path(registry_id: registry.id))
      expect(page).to have_select(with_selected: registry.name)
    end

    it "hides create new registry button when selecting option" do
      expect(page).to have_content("Create new registry")
      select registry.name
      expect(page).not_to have_content("Create new registry")
    end

    it "shows an error message if model validation fails" do
      select registry.name
      fill_in "Name", with: mirror2.name
      fill_in "URL", with: mirror2.url
      click_button("Save")

      expect(page).to have_content("Name has already been taken")
      expect(page).to have_content("Url has already been taken")

      select registry.name
      fill_in "URL", with: "invalid url"
      click_button("Save")

      expect(page).to have_content("Url is not a valid URL")
    end

    it "shows an error message if url format is invalid" do
      fill_in "URL", with: "ftp://google.com"
      expect(page).to have_content("This is not a valid URL")
    end

    it "shows a warning message if url is not secure" do
      fill_in "URL", with: "http://google.com"
      expect(page).to have_content("Security warning")
    end

    it "does not show the certificate textarea if url is not secure" do
      fill_in "URL", with: "http://google.com"
      expect(page).not_to have_content("Certificate")
    end

    it "shows the certificate textarea if url is secure" do
      fill_in "URL", with: "https://google.com"
      expect(page).to have_content("Certificate")
    end
  end

  describe "#edit" do
    before do
      visit edit_settings_registry_mirror_path(mirror)
    end

    it "forbids the user to change registry" do
      expect(page).to have_css(".registry-select[disabled]")
    end

    it "does not show create new registry button" do
      expect(page).not_to have_content("Create new registry")
    end

    it "allows an user to update an existent mirror (secure)" do
      fill_in "URL", with: "https://google.com"
      click_button("Save")

      expect(page).to have_content("Mirror was successfully updated.")
    end

    it "allows an user to update an existent mirror (insecure)" do
      fill_in "URL", with: "https://google.com"
      click_button("Save")

      expect(page).to have_content("Mirror was successfully updated.")
      expect(page).not_to have_content("Certificate")
    end

    it "shows an error message if model validation fails" do
      fill_in "Name", with: mirror2.name
      fill_in "URL", with: mirror2.url
      click_button("Save")

      expect(page).to have_content("Name has already been taken")
      expect(page).to have_content("Url has already been taken")

      fill_in "URL", with: "invalid url"
      click_button("Save")

      expect(page).to have_content("Url is not a valid URL")
    end

    it "shows an error message if url format is invalid" do
      fill_in "URL", with: "ftp://google.com"
      expect(page).to have_content("This is not a valid URL")
    end

    it "shows a warning message if url is not secure" do
      fill_in "URL", with: "http://google.com"
      expect(page).to have_content("Security warning")
    end

    it "does not show the certificate textarea if url is not secure" do
      fill_in "URL", with: "http://google.com"
      expect(page).not_to have_content("Certificate")
    end

    it "shows the certificate textarea if url is secure" do
      fill_in "URL", with: "https://google.com"
      expect(page).to have_content("Certificate")
    end
  end

  describe "#show" do
    before do
      visit settings_registry_mirror_path(mirror)
    end

    it "allows an user to delete a mirror" do
      accept_alert do
        click_on("Delete")
      end

      expect(page).not_to have_content(mirror.name)
      expect(page).to have_content("Mirror was successfully removed.")
      expect(page).to have_current_path(settings_registry_mirrors_path)
    end

    it "allows an user to go to a mirror's edit page" do
      click_on("Edit")

      expect(page).to have_current_path(edit_settings_registry_mirror_path(mirror))
    end

    it "allows an user to go to a registry's details page" do
      click_link(registry.name)

      expect(page).to have_current_path(settings_registry_path(mirror.registry))
    end
  end
end
# rubocop:enable RSpec/ExampleLength
