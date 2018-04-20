# frozen_string_literal: true
require "velum/salt"
# CloudCluster represents user-configured attributes of a cloud deployment.
class CloudCluster
  include ActiveModel::Model
  attr_accessor :cloud_framework,
    :instance_count, :instance_type, :instance_type_custom, :subnet_id,
    :security_group_id, # EC2 profile
    :subscription_id, :tenant_id, :client_id, :secret, # Azure provider
    :storage_account, :resource_group, :network_id # Azure profile

  def initialize(*args)
    super
    if @instance_type.blank? || @instance_type == "CUSTOM"
      @instance_type = instance_type_custom
    end
    @instance_count = @instance_count.to_i
  end

  # attributes that will be described via to_s as a scoping description
  def string_scoping_attributes
    [:resource_group, :network_id, :subnet_id, :security_group_id]
  end

  def to_s
    parts = ["a cluster of #{@instance_count} #{@instance_type} instances"]
    string_scoping_attributes.each do |attribute|
      parts.push(string_scope_if(attribute))
    end
    case @cloud_framework
    when "ec2"
      parts.push("in EC2")
    when "azure"
      parts.push("in Azure")
    end
    parts.compact.join(" ")
  end

  def save!
    # cloud.provider pillars
    persist_to_pillar!(:azure_subscription_id, @subscription_id)
    persist_to_pillar!(:azure_tenant_id, @tenant_id)
    persist_to_pillar!(:azure_client_id, @client_id)
    persist_to_pillar!(:azure_secret, @secret)
    # cloud.profile pillars
    persist_to_pillar!(:cloud_worker_type, @instance_type)
    persist_to_pillar!(:cloud_storage_account, @storage_account)
    persist_to_pillar!(:cloud_worker_resourcegroup, @resource_group)
    persist_to_pillar!(:cloud_worker_netgroup, @resource_group)
    persist_to_pillar!(:cloud_worker_net, @network_id)
    persist_to_pillar!(:cloud_worker_subnet_aws, @subnet_id)
    persist_to_pillar!(:cloud_worker_subnet_azure, @subnet_id)
    persist_to_pillar!(:cloud_worker_security_group, @security_group_id)
    Velum::Salt.call(action: "saltutil.refresh_pillar")
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

  def string_scope_if(attribute)
    value = send(attribute)
    description = attribute.to_s.humanize(capitalize: false)
    return unless value

    "in the #{value} #{description}"
  end

  def persist_to_pillar!(key, value)
    return unless value && Pillar.all_pillars[key]

    pillar = Pillar.find_or_initialize_by(pillar: Pillar.all_pillars[key])
    pillar.value = value
    pillar.save!
  end
end
