# ApplicationController is the superclass of all controllers.
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_to_setup
  protect_from_forgery with: :exception

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    logger.error exception
    not_found
  end

  private

  def redirect_to_setup
    return true unless signed_in?
    redirect_to setup_path unless setup_done?
  end

  # setup means the setup phase was completed
  def setup_done?
    Pillar.exists?(pillar: [Pillar.all_pillars[:apiserver],
                            Pillar.all_pillars[:dashboard_external_fqdn]])
  end

  def accessible_hosts
    [
      Pillar.value(pillar: :dashboard),
      Pillar.value(pillar: :dashboard_external_fqdn)
    ].uniq
  end

  def known_host?
    accessible_hosts.include?(request.host) || accessible_hosts.include?(request.host_with_port)
  end

  def not_found
    respond_to do |format|
      format.html do
        render file: Rails.root.join("public", "404"), layout: false, status: :not_found
      end
      format.any { head :not_found }
    end
  end
end
