# Serve the pillar information
class InternalApi::V1::PillarsController < InternalApiController
  def show
    ok content: pillar_contents.merge(non_pillar_contents)
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

  # extra non pillar structures we need to have visible in salt
  def non_pillar_contents
    registry_contents
  end

  def registry_contents
    {
      registries: [].tap do |res|
        DockerRegistry.all.each do |reg|
          res << {
            url:         reg.url,
            mirror:      reg.mirror,
            certificate: Certificate.find(reg.certifiable_id).certificate
          }
        end
      end
    }
  end
end
