# model that represents a docker registry
class DockerRegistry < ActiveRecord::Base
  belongs_to :certificate, polymorphic: true

  validates :url, presence: true
  validates :url, uniqueness: true
  validates :url, url: { schemes: ["https", "http"] }
  class << self
    def apply(settings_params)
      errors = []
      settings_params["registries"].each do |registry|
        errors << configure_registry(registry) if registry["docker_registry_url"].present?
      end
      cleanup(settings_params)
      errors
    end

    private

    # create or update DockerRegistry model
    def configure_registry(registry)
      url     = registry["docker_registry_url"]
      cert    = registry["docker_registry_certificate"]
      mirror  = registry["docker_registry_mirror"]

      certifiable_id, errors = configure_certificate(cert)

      find_or_initialize_by(url: url).tap do |r|
        r.url = url
        r.certifiable_id = certifiable_id
        r.certifiable_type = certifiable_id || :docker_registry
        r.mirror = mirror
        errors << "Registry url #{url} doesn't match a docker registry pattern" unless r.save
      end

      errors
    end

    # create or update Certificate model
    def configure_certificate(cert)
      errors = []
      return [nil, errors] if cert.blank?
      certificate = Certificate.find_or_initialize_by(certificate: cert).tap do |c|
        c.certificate = cert
        errors << "Failed to validate certificate" unless c.save
      end
      [certificate.id, errors]
    end

    # remove old registries from the db if they were deleted in the UI
    def cleanup(settings_params)
      passed_registries = settings_params["registries"].collect do |r|
        r["docker_registry_url"]
      end
      saved_registries = all.map(&:url)

      (saved_registries - passed_registries).each do |registry|
        r = find_by(url: registry)
        Certificate.delete(r.certifiable_id)
        r.delete
      end
    end
  end
end
