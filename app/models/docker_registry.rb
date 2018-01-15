# model that represents a docker registry
class DockerRegistry < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :url, presence: true, uniqueness: true, url: { schemes: ["https", "http"] }

  scope :is_mirror, -> { where.not(mirror: nil) }
  scope :is_registry, -> { where(mirror: nil) }

  class << self
    def apply(registries_params)
      errors = []
      registries_params.each do |registry|
        errors += configure_registry(registry) if registry["url"].present?
      end
      cleanup registries_params
      errors
    end

    private

    # create or update DockerRegistry model
    def configure_registry(registry)
      errors      = []
      url         = registry["url"]
      cert        = registry["certificate"]
      mirror      = registry["mirror"]

      registry = DockerRegistry.find_or_create_by(url: url) do |r|
        r.mirror = mirror
      end

      unless registry.persisted?
        errors << "Registry url #{url} doesn't match a docker registry pattern"
        return errors
      end

      if cert.present?
        certificate = Certificate.find_or_create_by(certificate: cert.strip)
        unless certificate.persisted?
          errors << "Failed to validate certificate"
          return errors
        end

        CertificateService.create(service: registry, certificate: certificate)
      elsif registry.certificate.present?
        registry.certificate_service.destroy
      end

      errors
    end

    # remove old registries from the db if they were deleted in the UI
    def cleanup(registries_params)
      passed_registries = registries_params.collect do |r|
        r["url"]
      end
      saved_registries = DockerRegistry.pluck(:url)
      DockerRegistry.where(url: saved_registries - passed_registries).destroy_all
    end
  end
end
