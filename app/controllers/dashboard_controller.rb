# frozen_string_literal: true

require "velum/kubernetes"

# DashboardController shows the main page.
class DashboardController < ApplicationController
  def index
    @assigned_minions = Minion.assigned_role
    @unassigned_minions = Minion.unassigned_role

    respond_to do |format|
      format.html
      format.json do
        render json: { assigned_minions:   @assigned_minions,
                       unassigned_minions: @unassigned_minions }
      end
    end
  end

  def kubectl_config
    kubeconfig = Velum::Kubernetes.kubeconfig
    @apiserver_host = kubeconfig.host
    @ca_crt = kubeconfig.ca_crt
    @client_crt = kubeconfig.client_crt
    @client_key = kubeconfig.client_key
    if [@apiserver_host, @ca_crt, @client_crt, @client_key].none?(&:blank?)
      response.headers["Content-Disposition"] = "attachment; filename=kubeconfig"
      render "kubeconfig.erb", layout: false, content_type: "text/yaml"
    else
      redirect_to root_path,
                  alert: "Provisioning did not yet finish. Please wait until the cluster is ready."
    end
  end
end
