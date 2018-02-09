# model that represents a registry mirror
class RegistryMirror < ActiveRecord::Base
  belongs_to :registry
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true, uniqueness: true, allow_blank: true,
                  url: { schemes: ["https", "http"] }
end
