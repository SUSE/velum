# frozen_string_literal: true
FactoryGirl.define do
  factory :minion do
    sequence(:hostname) { |n| "hostname#{n}" }
  end
end
