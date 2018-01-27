# frozen_string_literal: true
require "velum/salt"
# CloudCluster represents user-configured attributes of a cloud deployment.
class CloudCluster
  include ActiveModel::Model
  attr_accessor :cloud_framework,
    :instance_count, :instance_type, :instance_type_custom,
    :subnet_id, :security_group_id # EC2

  def initialize(*args)
    super
    if @instance_type.blank? || @instance_type == "CUSTOM"
      @instance_type = instance_type_custom
    end
    @instance_count = @instance_count.to_i
  end

  def to_s
    parts = ["a cluster of #{@instance_count} #{@instance_type} instances"]
    parts.push("in the #{@subnet_id} subnet") if @subnet_id
    parts.push("in the #{@security_group_id} security group") if @security_group_id
    case @cloud_framework
    when "ec2"
      parts.push("in EC2")
    end
    parts.join(" ")
  end

  def save!
    case @cloud_framework
    when "ec2"
      persist_to_pillar!(:cloud_worker_type, @instance_type)
      persist_to_pillar!(:cloud_worker_subnet, @subnet_id)
      persist_to_pillar!(:cloud_worker_security_group, @security_group_id)
      Velum::Salt.call(action: "saltutil.refresh_pillar")
    end
  end

  def save
    save!
    return true
  rescue ActiveRecord::ActiveRecordError,
         Velum::SaltApi::SaltConnectionException => e
    errors[:base] << e.message
    return false
  end

  private

  def persist_to_pillar!(pillar_key, value)
    pillar = Pillar.find_or_initialize_by(pillar: Pillar.all_pillars[pillar_key])
    pillar.value = value
    pillar.save!
  end
end
