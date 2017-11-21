# Serve the pillar information
class InternalApi::V1::PillarsController < InternalApiController
  def show
    ok content: pillar_contents
  end

  private

  def pillar_contents
    pillar_struct = {}.tap do |h|
      Pillar.all_pillars.collect { |k, v| h[v] = Pillar.value(pillar: k.to_sym) }
    end
    {}.tap do |json_response|
      pillar_struct.each do |key, value|
        json_response.deep_merge! key.split(":").reverse.inject(value) { |a, n| { n => a } }
      end
    end.deep_symbolize_keys
  end
end
