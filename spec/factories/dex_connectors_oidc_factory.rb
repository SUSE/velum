FactoryGirl.define do
  factory :dex_connector_oidc do
    sequence(:name) { |n| "OIDC Server #{n}" }
    provider_url  "http://your.fqdn.here:5556/dex"
    callback_url  "http://well.formed.but.invalid/" # needed for database cleaner :/
    client_id     "example-app"
    client_secret "ZXhhbXBsZS1hcHAtc2VjcmV0"
    basic_auth    true

    trait :skip_validation do
      to_create { |instance| instance.save(validate: false) }
    end
  end
end
