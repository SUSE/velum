FactoryGirl.define do
  factory :salt_job do
    jid { Time.current.strftime("%Y%m%d%H%M%S%6NS") }
  end
end
