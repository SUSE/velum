require "rails_helper"
require "velum/instance_type"

describe "Feature: Bootstrap a cluster in GCE" do
  let(:user) { create(:user) }
  let(:instance_types) { Velum::InstanceType.for("gce") }
  let(:custom_instance_type) { OpenStruct.new(key: "CUSTOM") }

  before do
    login_as user, scope: :user
    create(:gce_pillar)
    visit setup_worker_bootstrap_path
  end

  it "refers to GCE in the heading" do
    expect(page).to have_css("h1", text: "Google Compute Engine")
  end

  it "allows selection of an instance type" do
    instance_types.each do |instance_type|
      expect(page).to have_css(instance_type_radio_finder(instance_type))
    end
  end

  it "displays the category of the selected instance type", js: true do
    instance_types.each do |instance_type|
      click_instance_type_radio(instance_type)
      expect(page).to have_text(:visible, instance_type.category.name)
      expect(page).to have_text(:visible, instance_type.category.description)
    end
  end
end
