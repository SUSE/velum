require "rails_helper"
require "velum/instance_type"

describe "Feature: Bootstrap a cluster in EC2" do
  let(:user) { create(:user) }
  let(:instance_types) { Velum::InstanceType.for("ec2") }
  let(:custom_instance_type) { OpenStruct.new(key: "CUSTOM") }

  before do
    login_as user, scope: :user
    create(:ec2_pillar)
    visit setup_worker_bootstrap_path
  end

  it "refers to EC2 in the heading" do
    expect(page).to have_css("h1", text: "Elastic Compute Cloud")
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

  it "hides the custom instance type box by default", js: true do
    expect(page).not_to have_css("input#cloud_cluster_instance_type_custom[type='text']")
  end

  it "shows the textbox when choosing a custom instance type", js: true do
    click_instance_type_radio(custom_instance_type)
    expect(page).to have_css("input#cloud_cluster_instance_type_custom[type='text']")
  end

  context "when sizing the cluster" do
    let(:cluster_size) do
      page.find("#cloud_cluster_instance_count", visible: :any)["data-slider-value"].to_i
    end

    it "calculates the total cluster vCPU count", js: true do
      instance_types.each do |instance_type|
        total = instance_type.vcpu_count * cluster_size
        click_instance_type_radio(instance_type)
        expect(page).to have_css("#cluster-cpu-count", text: total)
      end
    end

    it "calculates the total cluster RAM size", js: true do
      instance_types.each do |instance_type|
        total = instance_type.ram_bytes * cluster_size
        click_instance_type_radio(instance_type)
        expect(page.find("#cluster-ram-size")["data-bytes"].to_i).to eq(total)
      end
    end

    it "hides calculations for custom types", js: true do
      click_instance_type_radio(custom_instance_type)
      expect(page).not_to have_css("#cluster-cpu-count")
      expect(page).not_to have_css("#cluster-ram-count")
    end
  end
end
