# SetupHelper contains all the view helpers for the setup process.
module SetupHelper
  def cloud_provider_options
    [
      ["OpenStack", :openstack]
    ]
  end

  def cloud_providers_options_for_select
    options_for_select(cloud_provider_options, selected: @cloud_provider)
  end
end
