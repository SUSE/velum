class MigrateRegistryMirrorFromPillar < ActiveRecord::Migration
  def up
    url_pillar = Pillar.find_by(pillar: :suse_registry_mirror_url)
    cert_pillar = Pillar.find_by(pillar: :suse_registry_mirror_cert)
    if url_pillar
      registry = Registry.create(
        name: Registry::SUSE_REGISTRY_NAME,
        url:  Registry::SUSE_REGISTRY_URL
      )
      mirror = RegistryMirror.create(
        url: url_pillar.value,
        name: Registry::SUSE_REGISTRY_NAME,
        registry_id: registry.id
      )
      url_pillar.destroy
    end
    if cert_pillar
      cert = Certificate.create(certificate: cert_pillar.value)
      CertificateService.create(
        certificate_id: cert.id,
        service_id: mirror.id,
        service_type: mirror.class.name
      )
      cert_pillar.destroy
    end
  end

  def down
    mirror = RegistryMirror.find_by(name: Registry::SUSE_REGISTRY_NAME)
    if mirror
      Pillar.create(pillar: :suse_registry_mirror_url, value: mirror.url)
      cert_service = CertificateService.find_by(service_id: mirror.id)
      if cert_service
        Pillar.create(
          pillar: :suse_registry_mirror_cert,
          value: Certificate.find(cert_service.certificate_id).certificate
        )
      end
      mirror.destroy
      Registry.find_by(name: Registry::SUSE_REGISTRY_NAME).destroy
    end
  end
end
