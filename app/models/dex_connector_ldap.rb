# Model that represents a dex authentication connector for LDAP
class DexConnectorLdap < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service
  self.table_name = "dex_connectors_ldap"

  validates :name, presence: true
  validates :host, presence: true
  validates :port, presence: true, numericality: { only_integer: true }
  validates :bind_dn, presence: true, unless: :bind_anon
  validates :bind_pw, presence: true, unless: :bind_anon
  validates :username_prompt, presence: true
  validates :user_base_dn, presence: true
  validates :user_filter, presence: true
  validates :user_attr_username, presence: true
  validates :user_attr_id, presence: true
  validates :user_attr_email, presence: true
  validates :user_attr_name, presence: true
  validates :group_base_dn, presence: true
  validates :group_filter, presence: true
  validates :group_attr_user, presence: true
  validates :group_attr_group, presence: true
  validates :group_attr_name, presence: true
end
