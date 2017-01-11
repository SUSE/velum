# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    sequence(:name)  { |n| "username#{n}" }
    sequence(:email) { |n| "test#{n}@localhost.test.lan" }
    password "test-password"
  end
end
