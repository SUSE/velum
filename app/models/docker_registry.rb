# model that represents a docker registry
class DockerRegistry < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :url, presence: true, uniqueness: true, url: { schemes: ["https", "http"] }

  class << self
    def apply(settings_params)
      errors = []
      settings_params["registries"].each do |registry|
        errors += configure_registry(registry) if registry["docker_registry_url"].present?
      end
      cleanup settings_params
      errors
    end

    private

    # create or update DockerRegistry model
    def configure_registry(registry)
      errors      = []
      url         = registry["docker_registry_url"]
      cert        = registry["docker_registry_certificate"]
      mirror      = registry["docker_registry_mirror"]

      if cert.present?
        certificate = Certificate.find_or_create_by certificate: cert.strip
        errors << "Failed to validate certificate" unless certificate.persisted?
      end

      service = DockerRegistry.find_or_create_by(url: url) do |r|
        r.mirror = mirror
        r.certificate = certificate
      end

      unless service.persisted?
        errors << "Registry url #{url} doesn't match a docker registry pattern"
      end

      errors
    end

    # remove old registries from the db if they were deleted in the UI
    def cleanup(settings_params)
      passed_registries = settings_params["registries"].collect do |r|
        r["docker_registry_url"]
      end
      saved_registries = DockerRegistry.pluck :url
      DockerRegistry.where(url: saved_registries - passed_registries).destroy_all
    end
  end
end
