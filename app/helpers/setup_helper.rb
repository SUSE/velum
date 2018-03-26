# SetupHelper contains all the view helpers for the setup process.
module SetupHelper
  def cloud_framework_value
    Pillar.value(pillar: :cloud_framework)
  end

  def cloud_provider_options?
    ["openstack"].include?(cloud_framework_value)
  end
end
