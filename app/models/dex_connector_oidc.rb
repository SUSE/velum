# Model that represents a dex authentication connector for OIDC
class DexConnectorOidc < ActiveRecord::Base
  self.table_name = "dex_connectors_oidc"

  validates :name,          presence: true
  validates :provider_url,  presence: true, oidc_provider: true
  validates :client_id,     presence: true
  validates :client_secret, presence: true
  validates :callback_url,  presence: true, http_url: true
  validates :basic_auth,    presence: true
end
