# KubeletComputeResourcesReservation represents the pillar values
# used to configure kubelet resource reservations.
class KubeletComputeResourcesReservation < ApplicationRecord
  validates :component, inclusion: {
    in: %w[kube system], message: "%<value>s is not a valid component"
  }
  validates :cpu, format: {
    with: /\A(\d+(\.\d+|m))?\z/, message: "%<value>s format invalid"
  }

  validates :memory, format: {
    with: ::EvictionValidator::BYTES_REGEXP, message: "%<value>s format invalid"
  }

  validates :ephemeral_storage, format: {
    with: ::EvictionValidator::BYTES_REGEXP, message: "%<value>s format invalid"
  }
end
