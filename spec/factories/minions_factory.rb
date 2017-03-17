# frozen_string_literal: true
FactoryGirl.define do
  factory :minion do
    sequence(:hostname) { |n| "hostname#{n}.domain.com" }
  end
  factory :master_minion, parent: :minion do
    role :master
  end
  factory :master_applied_minion, parent: :master_minion do
    highstate :applied
  end
  factory :worker_minion, parent: :minion do
    role :minion
  end
end
