# frozen_string_literal: true
FactoryGirl.define do
  factory :orchestration do
    jid    "20170706104527757674"
    kind   "bootstrap"
    status "in_progress"
  end
  factory :upgrade_orchestration, parent: :orchestration do
    kind "upgrade"

    after(:build) do |orchestration|
      orchestration.class.skip_callback :create, :after, :update_minions
    end
  end
end
