# System certificates represents CA certificates that should be
# installed in a system-wide used location: e.g. /etc/pki/trust/anchors
class SystemCertificate < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :name, presence: true, uniqueness: true
end
