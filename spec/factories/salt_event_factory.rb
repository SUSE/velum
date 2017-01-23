# frozen_string_literal: true
FactoryGirl.define do
  factory :salt_event do
    tag "salt/minion/MyMinion/start"
    data({ "_stamp" => "2017-01-23T15:32:32.913621", "pretag" => nil,
          "cmd" => "_minion_event", "tag" => "salt/minion/MyMinion/start",
          "data" => "Minion MyMinion started at Mon Jan 23 15:32:32 2017",
          "id" => "MyMinion" }.to_json)
    master_id "TheMaster"
    alter_time Time.current
  end
end
