FactoryGirl.define do
  factory :system_certificate do
    sequence(:name) { |n| "system_certificate#{n}" }
  end
end
