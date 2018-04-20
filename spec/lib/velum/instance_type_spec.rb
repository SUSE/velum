require "rails_helper"
require "velum/instance_type"

describe Velum::InstanceType do
  # the InstanceType is basically a convenience class for accessing data
  # in the relevant config files... so the tests center around verifying that
  # the config files load properly and the expected attributes are available.

  frameworks = ["azure", "ec2", "gce"]

  frameworks.each do |framework|
    describe "framework: #{framework}" do
      described_class.for(framework).each do |instance_type|
        describe "instance_type: #{instance_type.key}" do
          it "has a key" do
            expect(instance_type.key).not_to be_blank
          end
          it "has a sort value" do
            expect(instance_type.sort_value).not_to be_blank
          end
          it "has a vCPU count" do
            expect(instance_type.vcpu_count).not_to be_blank
          end
          it "has a RAM size in bytes" do
            expect(instance_type.ram_bytes).not_to be_blank
          end
          it "defines a unit scale for RAM" do
            expect(instance_type.ram_si_units).to be_truthy.or be_falsey
          end
          it "may have a list of details" do
            expect(instance_type.details).to be_an(Enumerable)
          end
          it "has a category" do
            expect(instance_type.category).not_to be_blank
          end
          it "has a category name" do
            expect(instance_type.category.name).not_to be_blank
          end
          it "has a category description" do
            expect(instance_type.category.description).not_to be_blank
          end
          it "has a list of category features" do
            expect(instance_type.category.features).to be_an(Enumerable)
          end
        end
      end
    end
  end
end
