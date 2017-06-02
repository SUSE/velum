# frozen_string_literal: true
FactoryGirl.define do
  factory :minion do
    sequence(:minion_id) { SecureRandom.hex }
    sequence(:fqdn)      { |n| "hostname#{n}.domain.com" }
  end
  factory :master_minion, parent: :minion do
    role :master
  end
  factory :worker_minion, parent: :minion do
    role :worker
  end
end
