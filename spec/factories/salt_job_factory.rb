FactoryGirl.define do
  factory :salt_job do
    jid { Time.current.strftime("%Y%m%d%H%M%S%6NS") }

    factory :salt_job_failed do
      retcode 1
      master_trace { FFaker::Lorem.sentence }
    end
  end
end
