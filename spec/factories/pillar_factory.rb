FactoryGirl.define do
  factory :pillar do
    sequence(:pillar) { |n| "key#{n}" }
    value "value"
  end
  factory :external_fqdn_pillar, parent: :pillar do
    pillar { Pillar.all_pillars[:apiserver] }
    value  "myapiserver.example.com"
  end
  factory :ec2_pillar, parent: :pillar do
    pillar { Pillar.all_pillars[:cloud_framework] }
    value  "ec2"
  end
  factory :openstack_pillar, parent: :pillar do
    pillar { Pillar.all_pillars[:cloud_provider] }
    value  "openstack"
  end
  factory :azure_pillar, parent: :pillar do
    pillar { Pillar.all_pillars[:cloud_framework] }
    value "azure"
  end
end
