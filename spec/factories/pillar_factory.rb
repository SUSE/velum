# frozen_string_literal: true
FactoryGirl.define do
  factory :pillar do
    sequence(:pillar) { |n| "key#{n}" }
    value "value"
  end
end
