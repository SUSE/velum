# SettingsHelper contains all the view helpers related/used in registries/mirrors templates.
module SettingsHelper
  def settings_path?
    request.fullpath.starts_with?(settings_path)
  end

  def settings_registries_path?
    request.fullpath.starts_with?(settings_registries_path)
  end

  def settings_registry_mirrors_path?
    request.fullpath.starts_with?(settings_registry_mirrors_path)
  end

  def registries_options_for_select
    registries = Registry.suse + Registry.displayable
    registries_for_options = registries.collect { |r| [r.name, r.id] }

    if params[:registry_id].present?
      options_for_select(registries_for_options, selected: params[:registry_id])
    else
      registries_for_options
    end
  end

  def display_registry_url(url)
    if url_secure?(url)
      content_tag(:i, nil, class: "fa fa-lock") + " " + url
    else
      url
    end
  end

  def url_secure?(url)
    url.starts_with?("https://") unless url.nil?
  end

  def suse_registry?(registry)
    registry.name == Registry::SUSE_REGISTRY_NAME
  end
end
