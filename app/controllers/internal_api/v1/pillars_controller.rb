# Serve the pillar information
class InternalApi::V1::PillarsController < InternalApiController
  def show
    ok content: pillar_contents.merge(registry_contents)
  end

  private

  def pillar_contents
    pillar_struct = {}.tap do |h|
      Pillar.all_pillars.each do |k, v|
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
    registries = DockerRegistry.is_registry.map do |reg|
      {
        url:  reg.url,
        cert: (reg.certificate.present? ? reg.certificate.certificate : nil)
      }
    end
    registry_mirrors = DockerRegistry.is_mirror.group(:mirror).pluck(:mirror)
    registry_mirrors.map! do |remote_registry_url|
      {
        url:     remote_registry_url,
        mirrors: DockerRegistry.where(mirror: remote_registry_url).map do |reg|
          {
            url:  reg.url,
            cert: (reg.certificate.present? ? reg.certificate.certificate : nil)
          }
        end
      }
    end
    { registries: (registries + registry_mirrors) }
  end
end
