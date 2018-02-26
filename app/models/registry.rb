# model that represents a registry
class Registry < ActiveRecord::Base
  has_many :registry_mirrors, dependent: :destroy
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true, url: { schemes: ["https", "http"] }

  SUSE_REGISTRY_NAME = "SUSE".freeze
  SUSE_REGISTRY_URL  = "https://registry.suse.com".freeze

  class << self
    # create or update suse Registry model
    # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize
    def configure_suse_registry(suse_registry_mirror_params)
      if suse_registry_mirror_params.blank? ||
          suse_registry_mirror_params["mirror_url"].blank?
        RegistryMirror.where(name: SUSE_REGISTRY_NAME).destroy_all
        return []
      end

      errors      = []
      cert        = suse_registry_mirror_params["certificate"]
      mirror_url  = suse_registry_mirror_params["mirror_url"]
      name        = suse_registry_mirror_params["name"] || SUSE_REGISTRY_NAME

      registry = Registry.where(name: SUSE_REGISTRY_NAME).first_or_initialize.tap do |r|
        r.url = SUSE_REGISTRY_URL
        r.save
      end

      suse_registry_mirror = RegistryMirror.where(name: name).first_or_initialize.tap do |m|
        m.url = mirror_url
        m.registry_id = registry.id
        m.save
      end

      if suse_registry_mirror.errors.present? || !suse_registry_mirror.persisted?
        errors << "Registry mirror url #{mirror_url} doesn't match a registry pattern"
        return errors
      end

      if cert.present?
        certificate = Certificate.find_or_create_by(certificate: cert.strip)

        CertificateService.create(service: suse_registry_mirror, certificate: certificate)
      elsif suse_registry_mirror.certificate.present?
        suse_registry_mirror.certificate_service.destroy
      end

      errors
    end
    # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize
  end
end
