# Model that represents a dex authentication connector for LDAP
class DexConnectorLdap < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service
  self.table_name = "dex_connectors_ldap"
end
