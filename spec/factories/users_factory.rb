FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@localhost.test.lan" }
    password "test-password"
  end
end
