# frozen_string_literal: true

require "velum/salt"

# SetupController is responsible for everything related to the bootstrapping
# process:
# welcoming, setting certain general settings, master selection, discovery and
# bootstrapping
class SetupController < ApplicationController
  rescue_from Minion::NonExistingMinion, with: :minion_not_found

  skip_before_action :redirect_to_setup
  before_action :redirect_to_dashboard
  before_action :check_empty_settings, only: :configure
  before_action :check_empty_bootstrap, only: :bootstrap

  def configure
    status = {}

    respond_to do |format|
      auto_pillars = { dashboard: request.host }

      Pillar.all_pillars.each do |key, pillar_key|
        pillar = Pillar.find_or_initialize_by pillar: pillar_key
        pillar.value = settings_params[key] || auto_pillars[key]
        next if pillar.save
        status[:failed_pillar] ||= []
        status[:failed_pillar].push(pillar.value)
      end

      if status[:failed_pillar]
        msg = "Failed to apply configuration to #{status[:failed_pillar].join(", ")}"
        format.html do
          flash[:alert] = msg
          redirect_to setup_worker_bootstrap_path
        end
        format.json { render json: msg, status: :unprocessable_entity }
      else
        format.html { redirect_to setup_worker_bootstrap_path }
        format.json { head :ok }
      end
    end
  end

  def ec2_configuration
    @conf = current_user.ec2_configuration_parsed
  end

  def update_ec2_configuration
    # Store pem key
    uploaded_pem = ec2_configuration_params[:pem_key]
    pem_key_path = Rails.root.join('tmp', 'pem_keys', uploaded_pem.original_filename).to_s
    pem_key_path_in_master = "/pem_keys/#{uploaded_pem.original_filename}"
    File.open(pem_key_path, 'wb'){ |file| file.write(uploaded_pem.read) }
    FileUtils.chmod 0600, pem_key_path
    #FileUtils.chown 'salt', nil, pem_key_path

    # Store the cloud provider otherwise the "create" action won't work
    create_ec2_provider('ec2-provider' => {
      'id' => ec2_configuration_params.delete(:keypair_id),
      'key' => ec2_configuration_params.delete(:keypair_key),
      'keyname' => ec2_configuration_params.delete(:keypair_keyname),
      'private_key' => pem_key_path_in_master,
      'driver' => 'ec2'
    })

    # Store the rest of the configuration in the database
    # TODO: Don't hardcode the path /pem_keys. This directory is tmp/pem_keys
    # on host, tmp/pem_keys on dashboard container and /pem_keys on master
    # container.
    current_user.update!(
      ec2_configuration: ec2_configuration_params.
      except(:number_of_minions, :pem_key).
      merge(pem_key_path: pem_key_path_in_master).to_json
    )

    ec2_configuration_params[:number_of_minions].to_i.times do |i|
      Velum::Salt.spawn_minion_ec2({
        instances: ["dkarakasilis_caasp_minion_#{i}"],
        master: ec2_configuration_params[:master_hostname],
        subnetid: ec2_configuration_params[:subnet_id],
        ssh_interface: ec2_configuration_params[:ssh_interface]
      })
    end

    redirect_to setup_discovery_path
  end

  def discovery
    @minions = Minion.all

    respond_to do |format|
      format.html
      format.json { render json: @minions }
    end
  end

  def bootstrap
    assigned = Minion.assign_roles!(roles: update_nodes_params)

    respond_to do |format|
      if assigned.values.include?(false)
        message = "Failed to assign #{failed_assigned_nodes(assigned)}"
        format.html do
          flash[:error] = message
          redirect_to setup_discovery_path
        end
        format.json { render json: message, status: :unprocessable_entity }
      else
        Velum::Salt.orchestrate
        format.html { redirect_to root_path }
        format.json { head :ok }
      end
    end
  end

  private

  def redirect_to_dashboard
    redirect_to root_path unless Minion.assigned_role.count.zero?
  end

  def settings_params
    params.require(:settings).permit(*Pillar.all_pillars.keys)
  end

  def update_nodes_params
    params.require(:roles)
  end

  def failed_assigned_nodes(assigned)
    assigned.select { |_name, success| !success }.keys.join(", ")
  end

  def minion_not_found(exception)
    respond_to do |format|
      format.html do
        flash[:error] = exception.message
        redirect_to setup_path
      end
      format.json { render json: exception.message, status: :not_found }
    end
  end

  def check_empty_settings
    return unless settings_params.values.any?(&:empty?)
    respond_to do |format|
      msg = "Please fill out all necessary form fields"
      format.html do
        redirect_to setup_path, alert: msg
      end
      format.json { render json: msg, status: :unprocessable_entity }
    end
  end

  def check_empty_bootstrap
    return if params.try(:[], "roles").try(:[], "master")
    respond_to do |format|
      msg = "Please select a master node"
      format.html do
        redirect_to setup_discovery_path, alert: msg
      end
      format.json { render json: msg, status: :unprocessable_entity }
    end
  end

  private

  # We need to store the provider information in a file where salt-cloud
  # expects to find it (/etc/salt/cloud.providers.d/). We can't pass provider
  # information to "cloud.create" action in salt-api.
  # See /lib/velum/salt.rb file, spawn_minion_ec2 method.
  def create_ec2_provider(conf)
    provider_path = Rails.root.join(
      'kubernetes', 'salt', 'cloud.providers.d', 'ec2.provider.conf').to_s

    File.open(provider_path, 'w') { |file| file.write(YAML.dump(conf)) }
  end

  def ec2_configuration_params
    params.require(:ec2_configuration).permit(
      :keypair_id, :keypair_key, :keypair_keyname, :master_hostname,
      :subnet_id, :ssh_interface, :pem_key, :number_of_minions)
  end
end
