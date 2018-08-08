# Settings::DexConnectorLdapsController is responsible to manage requests
# related to LDAP connectors.
class Settings::DexConnectorLdapsController < Settings::BaseCertificateController
  def index
    @ldap_connectors = DexConnectorLdap.all
  end

  def destroy
    @certificate_holder.destroy
    redirect_to settings_dex_connector_ldaps_path,
                notice: "LDAP Connector was successfully removed."
  end

  protected

  def certificate_holder_type
    DexConnectorLdap
  end

  def certificate_holder_params
    ldap_connector_params
  end

  def certificate_holder_update_params
    ldap_connector_params.except(:certificate, :current_cert)
  end

  private

  def ldap_connector_params
    params.require(:dex_connector_ldap).permit(:name, :host, :port,
                                               :start_tls, :certificate, :bind_anon,
                                               :bind_dn, :bind_pw, :username_prompt,
                                               :user_base_dn, :user_filter, :user_attr_username,
                                               :user_attr_id, :user_attr_email, :user_attr_name,
                                               :group_base_dn, :group_filter, :group_attr_user,
                                               :group_attr_group, :group_attr_name)
  end
end
