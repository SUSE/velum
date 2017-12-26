# Polymorphic proxy model that ties a Certificate to a Service
class CertificateService < ActiveRecord::Base
  belongs_to :certificate
  belongs_to :service, polymorphic: true

  validates :certificate, uniqueness: { scope: [:service_id, :service_type] }
end
