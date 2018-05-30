# KubeletComputeResourcesReservation represents the pillar values
# used to configure kubelet resource reservations.
class KubeletComputeResourcesReservation < ApplicationRecord
  BYTES_REGEX = /\A(\d+(e\d+)?([EPTGMK]i?)?)?\z/

  validates :component, inclusion: {
    in: %w[kube system], message: "%<value>s is not a valid component"
  }
  validates :cpu, format: {
    with: /\A(\d+(\.\d+|m))?\z/, message: "%<value>s format invalid"
  }

  validates :memory, format: {
    with: BYTES_REGEX, message: "%<value>s format invalid"
  }

  validates :ephemeral_storage, format: {
    with: BYTES_REGEX, message: "%<value>s format invalid"
  }
end
