FactoryGirl.define do
  factory :registry_mirror do
    sequence(:name) { |n| "mirror#{n}" }
    sequence(:url) { |n| "http://mirror-insecure#{n}.local.lan" }
    association :registry
  end
end
