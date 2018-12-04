require "rails_helper"
require "velum/salt_api"

describe CloudCluster do
  let(:custom_instance_type) { "custom-instance-type" }
  let(:subscription_id) { SecureRandom.uuid }
  let(:resource_group) { "azureresourcegroup" }
  let(:network_id) { "azurenetworkname" }
  let(:subnet_id) { "subnet-9d4a7b6c" }
  let(:security_group_id) { "sg-903004f8" }
  let(:instance_count) { 5 }
  let(:storage_account) { "azurestorageaccount" }

  it "can implicitly represent a custom instance type" do
    cluster = described_class.new(instance_type_custom: custom_instance_type)
    expect(cluster.instance_type).to be(custom_instance_type)
  end

  it "can explicity represent a custom instance type" do
    cluster = described_class.new(
      instance_type:        "CUSTOM",
      instance_type_custom: custom_instance_type
    )
    expect(cluster.instance_type).to be(custom_instance_type)
  end

  it "has a constant for minimum cluster size" do
    expect(described_class).to be_const_defined(:MIN_CLUSTER_SIZE)
  end

  it "has a constant for maximum cluster size" do
    expect(described_class).to be_const_defined(:MAX_CLUSTER_SIZE)
  end

  it "represents the current cluster size" do
    expect(described_class.new.current_cluster_size).to eq(0)

    3.times { create(:salt_job) }
    expect(described_class.new.current_cluster_size).to eq(3)
  end

  it "calculates the minimum number of nodes required for a cluster" do
    expect(described_class.new.min_nodes_required).to eq(described_class::MIN_CLUSTER_SIZE)

    described_class::MIN_CLUSTER_SIZE.times { create(:salt_job) }
    expect(described_class.new.min_nodes_required).to eq(0)
  end

  it "calculates maximum cluster growth" do
    expect(described_class.new.max_nodes_allowed).to eq(described_class::MAX_CLUSTER_SIZE)

    50.times { create(:salt_job) }
    expect(described_class.new.max_nodes_allowed).to eq(described_class::MAX_CLUSTER_SIZE - 50)
  end

  context "when represented as a string" do
    let(:cluster) do
      described_class.new(
        instance_type:     custom_instance_type,
        instance_count:    instance_count,
        resource_group:    resource_group,
        network_id:        network_id,
        subnet_id:         subnet_id,
        security_group_id: security_group_id
      )
    end

    it "counts out the instances" do
      substring = "a cluster of #{instance_count} #{custom_instance_type} instances"
      expect(cluster.to_s).to match(substring)
    end

    it "describes the resource group" do
      substring = "in the #{resource_group} resource group"
      expect(cluster.to_s).to match(substring)
    end

    it "describes the network" do
      substring = "in the #{network_id} network"
      expect(cluster.to_s).to match(substring)
    end

    it "describes the subnet" do
      substring = "in the #{subnet_id} subnet"
      expect(cluster.to_s).to match(substring)
    end

    it "describes the security group" do
      substring = "in the #{security_group_id} security group"
      expect(cluster.to_s).to match(substring)
    end
  end

  context "when saving, behave like ActiveRecord#save" do
    let(:cluster) { described_class.new }
    let(:handled_exceptions) do
      [
        ActiveRecord::ActiveRecordError.new("Didn't work!"),
        Velum::SaltApi::SaltConnectionException.new("You're bad at this.")
      ]
    end

    it "returns true" do
      allow(cluster).to receive(:save!)
      expect(cluster.save).to be(true)
    end

    it "returns false when there is an exception" do
      handled_exceptions.each do |exception|
        allow(cluster).to receive(:save!).and_raise(exception)
        expect(cluster.save).to be(false)
      end
    end

    it "captures downstream messages to the errors collection" do
      handled_exceptions.each do |exception|
        allow(cluster).to receive(:save!).and_raise(exception)
        cluster.save
        expect(cluster.errors[:base]).to include(exception.message)
      end
    end
  end

  context "when framework is EC2" do
    let(:framework) { "ec2" }
    let(:cluster) do
      described_class.new(
        cloud_framework:   framework,
        instance_type:     custom_instance_type,
        subnet_id:         subnet_id,
        security_group_id: security_group_id
      )
    end

    it "stores instance type as :cloud_worker_type Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_type)).to eq(custom_instance_type)
    end

    it "stores subnet ID as :cloud_worker_subnet Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_subnet)).to eq(subnet_id)
    end

    it "stores security group ID as :cloud_worker_security_group Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_security_group)).to eq(security_group_id)
    end

    it "describes the framework in string representation" do
      substring = "in EC2"
      expect(cluster.to_s).to match(substring)
    end
  end

  context "when framework is Azure" do
    let(:framework) { "azure" }
    let(:cluster) do
      described_class.new(
        cloud_framework: framework,
        subscription_id: subscription_id,
        instance_type:   custom_instance_type,
        resource_group:  resource_group,
        network_id:      network_id,
        subnet_id:       subnet_id,
        storage_account: storage_account
      )
    end

    it "stores subscription id as :azure_subscription_id Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :azure_subscription_id)).to eq(subscription_id)
    end

    it "stores storage account as :cloud_storage_account Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_storage_account)).to eq(storage_account)
    end

    it "stores instance type as :cloud_worker_type Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_type)).to eq(custom_instance_type)
    end

    it "stores resource group name as :cloud_worker_resourcegroup Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_resourcegroup)).to eq(resource_group)
    end

    it "stores network name as :cloud_worker_net Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_net)).to eq(network_id)
    end

    it "stores subnet name as :cloud_worker_subnet Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_subnet)).to eq(subnet_id)
    end

    it "describes the framework in string representation" do
      substring = "in Azure"
      expect(cluster.to_s).to match(substring)
    end
  end

  context "when framework is GCE" do
    let(:framework) { "gce" }
    let(:cluster) do
      described_class.new(
        cloud_framework: framework,
        instance_type:   custom_instance_type,
        network_id:      network_id,
        subnet_id:       subnet_id
      )
    end

    it "stores instance type as :cloud_worker_type Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_type)).to eq(custom_instance_type)
    end

    it "stores network name as :cloud_worker_net Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_net)).to eq(network_id)
    end

    it "stores subnet name as :cloud_worker_subnetwork Pillar and refreshes" do
      ensure_pillar_refresh do
        expect(cluster.save).to be(true)
      end
      expect(Pillar.value(pillar: :cloud_worker_subnet)).to eq(subnet_id)
    end

    it "describes the framework in string representation" do
      substring = "in GCE"
      expect(cluster.to_s).to match(substring)
    end
  end

  context "when building" do
    let(:cluster) do
      described_class.new(
        instance_type:     custom_instance_type,
        instance_count:    instance_count,
        resource_group:    resource_group,
        network_id:        network_id,
        subnet_id:         subnet_id,
        security_group_id: security_group_id
      )
    end
    let(:error_message) { "[\"Nope!\"]" }

    it "captures jobs" do
      VCR.use_cassette("salt/cloud_profile", record: :none, allow_playback_repeats: true) do
        cluster.save!
        cluster.build!
        expect(SaltJob.all_open.count).to eq(instance_count)
      end
    end

    it "captures errors" do
      VCR.use_cassette("salt/login_500", record: :none, allow_playback_repeats: true) do
        cluster.save!
        cluster.build!
        expect(cluster.errors[:base]).to include(error_message)
      end
    end

    context "with prior failed jobs" do
      let(:failures) { 3 }

      before do
        failures.times { FactoryGirl.create(:salt_job_failed) }
      end

      it "clears failed jobs when (re)starting" do
        VCR.use_cassette("salt/cloud_profile", record: :none, allow_playback_repeats: true) do
          cluster.save!
          cluster.build!
          expect(SaltJob.failed.count).to be_zero
        end
      end
    end
  end
end
