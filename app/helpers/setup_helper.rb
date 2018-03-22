# SetupHelper contains all the view helpers for the setup process.
module SetupHelper
  def cloud_provider_value
    Pillar.value(pillar: :cloud_framework) || "openstack"
  end
end
