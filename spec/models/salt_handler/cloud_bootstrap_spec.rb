require "rails_helper"

describe SaltHandler::CloudBootstrap do
  let!(:jid) { Time.current.strftime("%Y%m%d%H%M%S%6N") }
  let(:node_id) { "caasp-node-" + SecureRandom.hex(8) }
  let(:ip) { FFaker::Internet.ip_v4_address }
  let(:instance_id) { "i-" + SecureRandom.hex(17) }
  let!(:job) { FactoryGirl.create(:salt_job, jid: jid) }
  let(:salt_event) do
    event_data = {
      "fun_args" => ["cluster_node", node_id],
      "jid"      => jid,
      "return"   => {
        node_id => {
          "productCodes"        => nil,
          "vpcId"               => "vpc-" + SecureRandom.hex(8),
          "instanceId"          => instance_id,
          "image"               => "ami-" + SecureRandom.hex(8),
          "imageId"             => "ami-" + SecureRandom.hex(8),
          "keyName"             => "caasp-ip-" + ip.tr(".", "-"),
          "clientToken"         => nil,
          "subnetId"            => "subnet-" + SecureRandom.hex(8),
          "amiLaunchIndex"      => "0",
          "instanceType"        => "t2.xlarge",
          "size"                => "t2.xlarge",
          "groupSet"            => {
            "item" => {
              "groupName" => "caasp-ip-" + ip.tr(".", "-"),
              "groupId"   => "sg-" + SecureRandom.hex(8)
            }
          },
          "monitoring"          => { "state" => "disabled" },
          "id"                  => instance_id,
          "state"               => "running",
          "dnsName"             => nil,
          "privateIpAddress"    => ip,
          "virtualizationType"  => "hvm",
          "privateDnsName"      => "ip-" + ip.tr(".", "-") + ".us-west-2.compute.internal",
          "reason"              => nil,
          "tagSet"              => {
            "item" => { "key" => "Name", "value" => node_id }
          },
          "deployed"            => true,
          "private_ips"         => ip,
          "sourceDestCheck"     => "true",
          "blockDeviceMapping"  => {
            "item" => {
              "deviceName" => "/dev/sda1",
              "ebs"        => {
                "status"              => "attached",
                "deleteOnTermination" => "true",
                "volumeId"            => "vol-" + SecureRandom.hex(17),
                "attachTime"          => FFaker::Time.datetime
              }
            }
          },
          "placement"           => {
            "groupName"        => nil,
            "tenancy"          => "default",
            "availabilityZone" => "us-west-2c"
          },
          "name"                => node_id,
          "instanceState"       => { "code" => "16", "name" => "running" },
          "networkInterfaceSet" => {
            "item" => {
              "status"                => "in-use",
              "macAddress"            => FFaker::Internet.mac,
              "sourceDestCheck"       => "true",
              "vpcId"                 => "vpc-" + SecureRandom.hex(8),
              "description"           => nil,
              "networkInterfaceId"    => "eni-" + SecureRandom.hex(8),
              "privateIpAddress"      => ip,
              "groupSet"              => {
                "item" => {
                  "groupName" => "caasp-ip-" + ip.tr(".", "-"),
                  "groupId"   => "sg-" + SecureRandom.hex(8)
                }
              },
              "attachment"            => {
                "status"              => "attached",
                "deviceIndex"         => "0",
                "deleteOnTermination" => "true",
                "attachmentId"        => "eni-attach-" + SecureRandom.hex(8),
                "attachTime"          => FFaker::Time.datetime
              },
              "subnetId"              => "subnet-" + SecureRandom.hex(8),
              "ownerId"               => FFaker::PhoneNumber.imei,
              "privateIpAddressesSet" => {
                "item" => {
                  "privateIpAddress" => ip,
                  "primary"          => "true",
                  "association"      => {
                    "publicIp"      => FFaker::Internet.ip_v4_address,
                    "publicDnsName" => nil,
                    "ipOwnerId"     => "amazon"
                  }
                }
              },
              "association"           => {
                "publicIp"      => FFaker::Internet.ip_v4_address,
                "publicDnsName" => nil,
                "ipOwnerId"     => "amazon"
              }
            }
          },
          "public_ips"          => FFaker::Internet.ip_v4_address,
          "ebsOptimized"        => "false",
          "launchTime"          => FFaker::Time.datetime,
          "architecture"        => "x86_64",
          "hypervisor"          => "xen",
          "rootDeviceType"      => "ebs",
          "ipAddress"           => FFaker::Internet.ip_v4_address,
          "rootDeviceName"      => "/dev/sda1"
        }
      },
      "retcode"  => 0,
      "success"  => true,
      "cmd"      => "_return",
      "_stamp"   => FFaker::Time.datetime,
      "fun"      => "cloud.profile",
      "id"       => "admin"
    }.to_json

    FactoryGirl.create(:salt_event,
      tag:  "salt/job/" + jid + "/ret/admin",
      data: event_data)
  end

  let(:failed_salt_event) do
    return_string = <<-RETURN
      The minion function caused an exception: Traceback (most recent call last):
      File "/usr/lib/python2.7/site-packages/salt/minion.py", line 1455, in _thread_return
      return_data = executor.execute()
      File "/usr/lib/python2.7/site-packages/salt/executors/direct_call.py", line 28, in execute
      return self.func(*self.args, **self.kwargs)
      File "/usr/lib/python2.7/site-packages/salt/modules/cloud.py", line 199, in profile_
      info = client.profile(profile, names, vm_overrides=vm_overrides, **kwargs)
      File "/usr/lib/python2.7/site-packages/salt/cloud/__init__.py", line 352, in profile   mapper.run_profile(profile, names, vm_overrides=vm_overrides)
      File "/usr/lib/python2.7/site-packages/salt/cloud/__init__.py", line 1465, in run_profile
      raise SaltCloudSystemExit('Failed to deploy VM')
      SaltCloudSystemExit: Failed to deploy VM
    RETURN

    event_data = {
      "fun_args" => ["cluster_node", node_id],
      "jid"      => "20180501164423788496",
      "return"   => return_string,
      "success"  => false,
      "cmd"      => "_return",
      "_stamp"   => FFaker::Time.datetime,
      "fun"      => "cloud.profile",
      "id"       => "admin",
      "out"      => "nested"
    }.to_json

    FactoryGirl.create(:salt_event,
      tag:  "salt/job/" + jid + "/ret/admin",
      data: event_data)
  end

  describe "when handling events" do
    let(:random_event) do
      FactoryGirl.create(:salt_event,
        tag:  "salt/job/" + jid + "/ret/" + jid,
        data: {}.to_json)
    end
    let(:admin_other_event) do
      FactoryGirl.create(:salt_event,
        tag:  "salt/job/" + jid + "/ret/admin",
        data: { "fun" => "foo.bar" }.to_json)
    end
    let(:untracked_event) do
      FactoryGirl.create(:salt_event,
        tag:  "salt/job/1/ret/admin",
        data: { "fun" => "cloud.profile" }.to_json)
    end

    it "returns false if job was not run on admin node" do
      expect(described_class).not_to be_can_handle_event(random_event)
    end

    it "returns false if job is not using 'cloud.profile' function" do
      expect(described_class).not_to be_can_handle_event(admin_other_event)
    end

    it "returns failse if job id is not tracked" do
      expect(described_class).not_to be_can_handle_event(untracked_event)
    end

    it "returns true if admin node job, 'cloud.profile' function, tracked job id" do
      expect(described_class).to be_can_handle_event(salt_event)
    end
  end

  describe "when processing events" do
    let(:handler) { described_class.new(salt_event) }
    let(:failed_handler) { described_class.new(failed_salt_event) }

    it "updates the job on a successful event" do
      handler.process_event
      job.reload
      expect(job).to be_completed
      expect(job).to be_succeeded
    end

    it "updates the job on a failed event" do
      failed_handler.process_event
      job.reload
      expect(job).to be_completed
      expect(job).to be_failed
    end
  end
end
