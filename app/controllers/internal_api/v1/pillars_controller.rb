# Serve the pillar information
# rubocop:disable Metrics/ClassLength
class InternalApi::V1::PillarsController < InternalApiController
  def show
    ok content: pillar_contents.merge(
      registry_contents
    ).merge(
      cloud_framework_contents
    ).merge(
      cloud_provider_contents
    ).merge(
      kubelet_contents
    )
  end

  private

  def pillar_contents
    pillar_struct = {}.tap do |h|
      Pillar.simple_pillars.each do |k, v|
        h[v] = Pillar.value(pillar: k.to_sym) unless Pillar.value(pillar: k.to_sym).nil?
      end
    end
    {}.tap do |json_response|
      pillar_struct.each do |key, value|
        json_response.deep_merge! key.split(":").reverse.inject(value) { |a, n| { n => a } }
      end
    end.deep_symbolize_keys
  end

  def registry_contents
    registries = Registry.all.map do |reg|
      registry = {}
      registry[:url]  = reg.url
      registry[:cert] = reg.certificate.try(:certificate)
      reg.registry_mirrors.each do |mirror|
        registry[:mirrors] ||= []
        registry[:mirrors].push(
          url:  mirror.url,
          cert: mirror.certificate.try(:certificate)
        )
      end
      registry
    end
    { registries: registries }
  end

  def cloud_framework_contents
    case Pillar.value(pillar: :cloud_framework)
    when "ec2"
      ec2_cloud_contents
    when "azure"
      azure_cloud_contents
    else
      {}
    end
  end

  def cloud_provider_contents
    case Pillar.value(pillar: :cloud_provider)
    when "openstack"
      openstack_cloud_contents
    else
      {}
    end
  end

  def ec2_cloud_contents
    {
      cloud: {
        framework: "ec2",
        profiles:  {
          cluster_node: {
            size:               Pillar.value(pillar: :cloud_worker_type),
            network_interfaces: [
              {
                DeviceIndex:              0,
                AssociatePublicIpAddress: false,
                SubnetId:                 Pillar.value(pillar: :cloud_worker_subnet),
                SecurityGroupId:          Pillar.value(pillar: :cloud_worker_security_group)
              }
            ]
          }
        }
      }
    }
  end

  def azure_cloud_contents
    {
      cloud: {
        framework: "azure",
        providers: {
          azure: {
            subscription_id: Pillar.value(pillar: :azure_subscription_id),
            tenant:          Pillar.value(pillar: :azure_tenant_id),
            client_id:       Pillar.value(pillar: :azure_client_id),
            secret:          Pillar.value(pillar: :azure_secret)
          }
        },
        profiles:  {
          cluster_node: {
            size:                   Pillar.value(pillar: :cloud_worker_type),
            storage_account:        Pillar.value(pillar: :cloud_storage_account),
            resource_group:         Pillar.value(pillar: :cloud_worker_resourcegroup),
            network_resource_group: Pillar.value(pillar: :cloud_worker_resourcegroup),
            network:                Pillar.value(pillar: :cloud_worker_net),
            subnet:                 Pillar.value(pillar: :cloud_worker_subnet)
          }
        }
      }
    }
  end

  def openstack_cloud_contents
    {
      cloud: {
        provider:  "openstack",
        openstack: {
          auth_url:       Pillar.value(pillar: :cloud_openstack_auth_url),
          username:       Pillar.value(pillar: :cloud_openstack_username),
          password:       Pillar.value(pillar: :cloud_openstack_password),
          domain:         Pillar.value(pillar: :cloud_openstack_domain),
          domain_id:      Pillar.value(pillar: :cloud_openstack_domain_id),
          project:        Pillar.value(pillar: :cloud_openstack_project),
          project_id:     Pillar.value(pillar: :cloud_openstack_project_id),
          region:         Pillar.value(pillar: :cloud_openstack_region),
          floating:       Pillar.value(pillar: :cloud_openstack_floating),
          subnet:         Pillar.value(pillar: :cloud_openstack_subnet),
          bs_version:     Pillar.value(pillar: :cloud_openstack_bs_version),
          lb_mon_retries: Pillar.value(pillar: :cloud_openstack_lb_mon_retries)
        }
      }
    }
  end

  def kubelet_contents
    reservations = {}
    KubeletComputeResourcesReservation.all.each do |r|
      reservations[r.component] = {
        cpu: r.cpu,
        memory: r.memory,
        "ephemeral-storage" => r.ephemeral_storage
      }
    end

    eviction_hard = Pillar.find_or_initialize_by(pillar: "kubelet:eviction-hard")

    {
      kubelet: {
        "compute-resources" => reservations,
        "eviction-hard"     => eviction_hard.value || ""
      }
    }
  end
end
# rubocop:enable Metrics/ClassLength
