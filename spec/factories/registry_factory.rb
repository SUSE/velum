FactoryGirl.define do
  factory :registry do
    sequence(:name) { |n| "registry#{n}" }
    sequence(:url) { |n| "http://insecure#{n}.local.lan" }
  end
end
