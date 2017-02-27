# frozen_string_literal: true
# Pillar represents a pillar value on Salt.
#
# This can override already existing pillar values, or create completely new ones.
#
# For example, given that we have on our static pillar:
#
#   certificate_information:
#     subject_properties:
#       C: DE
#       O: SUSE
#
# We could override them by creating the following Pillar records:
#
#   Pillar.create pillar: "certificate_information.subject_properties.C", value: "FR"
#   Pillar.create pillar: "certificate_information.subject_properties.O", value: "My Company"
#
# Lists can be represented as collisions. So, creating the following Pillar records:
#
#   Pillar.create pillar: "my_service.extra_ips", value: "127.0.0.1"
#   Pillar.create pillar: "my_service.extra_ips", value: "127.0.0.2"
#
# Would match the following YAML representation:
#
#   my_service:
#     extra_ips:
#       - 127.0.0.1
#       - 127.0.0.2
#
# This is because how we configure our salt master using this table as an external pillar. For
# further information you can visit:
#   - https://github.com/kubic-project/velum/blob/master/docs/salt.md
#   - https://github.com/kubic-project/velum/blob/master/kubernetes/salt/config/master.d/salt-master.conf
class Pillar < ApplicationRecord
  validates :pillar, presence: true
  validates :value, presence: true

  scope :global, -> { where minion_id: nil }
end
