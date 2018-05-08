# Settings::KubeletComputeResourcesReservations is responsibe to manage all the requests
# related to the kubelet compute resources reservations feature.
class Settings::KubeletComputeResourcesReservationsController < SettingsController
  def index
    @kube_reservations = KubeletComputeResourcesReservation.find_or_initialize_by(
      component: "kube"
    )
    @system_reservations = KubeletComputeResourcesReservation.find_or_initialize_by(
      component: "system"
    )
    @eviction_hard = Pillar.find_or_initialize_by(pillar: "kubelet:eviction-hard")
  end

  def create
    @kube_reservations = KubeletComputeResourcesReservation.find_or_initialize_by(
      component: "kube"
    )
    @system_reservations = KubeletComputeResourcesReservation.find_or_initialize_by(
      component: "system"
    )

    @kube_reservations.update_attributes(kube_reservation_params)
    @system_reservations.update_attributes(system_reservation_params)
    @eviction_hard = Pillar.find_or_initialize_by(pillar: "kubelet:eviction-hard")

    ActiveRecord::Base.transaction do
      @kube_reservations.save!
      @system_reservations.save!

      if eviction_hard_param.blank?
        @eviction_hard.destroy
        @eviction_hard = Pillar.find_or_initialize_by(pillar: "kubelet:eviction-hard")
      else
        @eviction_hard.value = eviction_hard_param
        @eviction_hard.save!
      end
    end

    redirect_to settings_kubelet_compute_resources_reservations_path,
      notice: "kubelet resource reservations successfully saved."
  rescue ActiveRecord::RecordInvalid
    render action: :index, status: :unprocessable_entity
  end

  private

  def kube_reservation_params
    ret = {}
    params.require(
      :kubelet_compute_resources_reservations
    ).permit(
      :kube_cpu,
      :kube_memory,
      :kube_ephemeral_storage
    ).each do |k, v|
      ret[k.gsub("kube_", "")] = v
    end
    ret
  end

  def system_reservation_params
    ret = {}
    params.require(
      :kubelet_compute_resources_reservations
    ).permit(
      :system_cpu,
      :system_memory,
      :system_ephemeral_storage
    ).each do |k, v|
      ret[k.gsub("system_", "")] = v
    end
    ret
  end

  def eviction_hard_param
    params["kubelet_compute_resources_reservations"]["eviction_hard"]
  end
end
