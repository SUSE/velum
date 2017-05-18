# frozen_string_literal: true
FactoryGirl.define do
  factory :pillar do
    sequence(:pillar) { |n| "key#{n}" }
    value "value"
  end
  factory :external_fqdn_pillar, parent: :pillar do
    pillar Pillar.all_pillars[:apiserver]
    value  "myapiserver.example.com"
  end
end
