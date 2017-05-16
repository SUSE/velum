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
#   Pillar.create pillar: "certificate_information:subject_properties:C", value: "FR"
#   Pillar.create pillar: "certificate_information:subject_properties:O", value: "My Company"
#
# Lists can be represented as collisions. So, creating the following Pillar records:
#
#   Pillar.create pillar: "my_service:extra_ips", value: "127.0.0.1"
#   Pillar.create pillar: "my_service:extra_ips", value: "127.0.0.2"
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
#   - https://github.com/kubic-project/salt/blob/master/config/master.d/returner.conf
class Pillar < ApplicationRecord
  validates :pillar, presence: true
  validates :value, presence: true

  scope :global, -> { where minion_id: nil }

  class << self
    def value(pillar:)
      Pillar.find_by(pillar: all_pillars[pillar]).try(:value)
    end

    def all_pillars
      {
        company_name: "certificate_information:subject_properties:O",
        company_unit: "certificate_information:subject_properties:OU",
        email:        "certificate_information:subject_properties:Email",
        country:      "certificate_information:subject_properties:C",
        state:        "certificate_information:subject_properties:ST",
        city:         "certificate_information:subject_properties:L",
        dashboard:    "dashboard"
      }
    end
  end
end
