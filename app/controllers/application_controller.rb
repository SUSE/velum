# frozen_string_literal: true

# ApplicationController is the superclass of all controllers.
class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: 500
  end
  before_action :force_ssl_redirect, unless: -> { Rails.env.test? }
  before_action :authenticate_user!
  before_action :redirect_to_setup
  protect_from_forgery with: :exception

  private

  def redirect_to_setup
    return true unless signed_in?
    redirect_to setup_path unless setup_done?
  end

  # setup means the setup phase was completed
  def setup_done?
    Pillar.exists? pillar: Pillar.all_pillars[:apiserver]
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
end
