# frozen_string_literal: true
require "rails_helper"

require "velum/ldap"

# Tests out that the LDAP integration works as expected.

feature "LDAP Integration feature" do
  let(:user) { build(:user) }

  let(:ldap_config) do
    # open LDAP connection
    cfg = ::Devise.ldap_config || Rails.root.join("config", "ldap.yml")
    YAML.safe_load(ERB.new(File.read(cfg)).result)[Rails.env]
  end

  let(:ldap) do
    conn_params = {
      host: ldap_config["host"],
      port: ldap_config["port"],
      auth: {
        method:   :simple,
        username: ldap_config["admin_user"],
        password: ldap_config["admin_password"]
      }
    }

    if ldap_config.key?("ssl")
      conn_params[:auth][:encryption] = ldap_config["ssl"].to_sym
    end

    Net::LDAP.new(**conn_params)
  end

  let(:people_base) { ldap_config["base"] }
  let(:group_base) { ldap_config["group_base"] }
  let(:admin_group) { ldap_config["required_groups"][0] }

  let(:uid) { user.email[0, user.email.index("@")] }
  let(:user_dn) { "uid=#{uid},#{people_base}" }

  before do
    # clear out LDAP
    # dependencies are hard here, and there's no such thing as a depth first search,
    # and sort order isn't guaranteed, so we run this a few times until we don't get
    # any error code 66 messages, guaranteeing that we've cleared the tree
    last_error = nil
    count = 0

    Kernel.loop do
      last_error = nil
      count += 1
      [admin_group, group_base, people_base].each do |base|
        ldap.search(base: base) do |entry|
          result = ldap.delete(dn: entry.dn)

          # 66 = Not Allowed On Non-Leaf, which means this entry has children
          op_result = ldap.get_operation_result
          last_error = op_result if !result && op_result.code == 66
        end
      end

      if count > 20
        # this is just to avoid an infinite loop. It really shouldn't happpen,
        # but if it does, you won't be scratching your head on why there is no
        # test output
        raise "after 20 tries, LDAP is not empty, failing"
      end

      break if last_error.nil?
    end
  end

  def tls_conn_params
    cfg = ::Devise.ldap_config || Rails.root.join("config", "ldap.yml")
    ldap_config = YAML.safe_load(ERB.new(File.read(cfg)).result)[Rails.env]

    ldap_config["ssl"] = "start_tls"

    conn_params = {
      host: ldap_config["host"],
      port: ldap_config["port"],
      auth: {
        method:   :simple,
        username: ldap_config["admin_user"],
        password: ldap_config["admin_password"]
      }
    }

    Velum::LDAP.configure_ldap_tls!(ldap_config, conn_params)

    conn_params
  end

  scenario "TLS is configured properly when needed" do
    expect(tls_conn_params[:auth][:encryption]).to be(:start_tls)
  end

  scenario "People org unit does not exist" do
    create_account

    expect(ldap.search(base: people_base,
                       return_result: false, scope: Net::LDAP::SearchScope_BaseObject)).to be(true)
  end

  scenario "Administrators groupOfUniqueNames does not exist" do
    create_account

    expect(ldap.search(base: admin_group,
                       return_result: false, scope: Net::LDAP::SearchScope_BaseObject)).to be(true)
  end

  def create_user_already_in_group
    # create the group OU
    group_dn = Net::LDAP::DN.new(group_base).to_a

    attrs = {
      ou:          group_dn[1],
      objectclass: ["top", "organizationalUnit"]
    }

    expect(ldap.add(dn: group_base, attributes: attrs)).to be(true)

    # create the admin group, adding the user
    admin_dn = Net::LDAP::DN.new(admin_group).to_a

    attrs = {
      cn:           admin_dn[1],
      objectclass:  ["top", "groupOfUniqueNames"],
      uniqueMember: user_dn
    }

    expect(ldap.add(dn: admin_group, attributes: attrs)).to be(true)
  end

  scenario "User is already a member of Administrators group" do
    create_user_already_in_group

    create_account

    expect(ldap.search(base: admin_group,
                      return_result: false, scope: Net::LDAP::SearchScope_BaseObject)).to be(true)
  end

  def create_group_without_member
    # create the group OU
    group_dn = Net::LDAP::DN.new(group_base).to_a

    attrs = {
      ou:          group_dn[1],
      objectclass: ["top", "organizationalUnit"]
    }

    expect(ldap.add(dn: group_base, attributes: attrs)).to be(true)

    # create the admin group, adding the user
    admin_dn = Net::LDAP::DN.new(admin_group).to_a

    attrs = {
      cn:           admin_dn[1],
      objectclass:  ["top", "groupOfUniqueNames"],
      uniqueMember: "uid=foo,#{people_base}"
    }

    expect(ldap.add(dn: admin_group, attributes: attrs)).to be(true)

    create_account

    Net::LDAP::Filter.eq("uniqueMember", user_dn)
  end

  scenario "User is not already a member of Administrators group" do
    expect(ldap.search(base: admin_group,
                      filter: create_group_without_member, return_result: false,
                      scope: Net::LDAP::SearchScope_BaseObject)).to be(true)
  end

  def create_people_ou
    people_dn = Net::LDAP::DN.new(people_base).to_a

    attrs = {
      ou:          people_dn[1],
      objectclass: ["top", "organizationalUnit"]
    }

    expect(ldap.add(dn: people_base, attributes: attrs)).to be(true)
  end

  def create_group_ou
    # create the group OU
    group_dn = Net::LDAP::DN.new(group_base).to_a

    attrs = {
      ou:          group_dn[1],
      objectclass: ["top", "organizationalUnit"]
    }

    expect(ldap.add(dn: group_base, attributes: attrs)).to be(true)
  end

  def create_admin_ou(member)
    # create the admin group, adding the user
    admin_dn = Net::LDAP::DN.new(admin_group).to_a

    attrs = {
      cn:           admin_dn[1],
      objectclass:  ["top", "groupOfUniqueNames"],
      uniqueMember: member
    }

    expect(ldap.add(dn: admin_group, attributes: attrs)).to be(true)
  end

  def create_user
    create_people_ou
    create_group_ou
    create_admin_ou("uid=foo,#{people_base}")

    attrs = {
      cn:           "A User",
      objectclass:  ["person", "inetOrgPerson"],
      uid:          uid,
      userPassword: user.password,
      givenName:    "A",
      sn:           "User",
      mail:         user.email
    }

    expect(ldap.add(dn: user_dn, attributes: attrs)).to be(true)
  end

  scenario "User already exists" do
    create_user
    create_account
  end

  scenario "Fail_if_with tests failure case" do
    expect { Velum::LDAP.fail_if_with(false, "Foobar") }.to raise_error(RuntimeError)
  end

  def setup_ldap_for_failure
    my_instance = instance_double(Devise::LDAP::Connection)
    allow(Devise::LDAP::Connection).to receive(:new).and_return(my_instance)
    e = DeviseLdapAuthenticatable::LdapException.new("expected")
    allow(my_instance).to receive(:authorized?).and_raise(e)

    login
  end

  def login
    visit setup_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button("Log in")
  end

  scenario "LDAP Failure causes 500" do
    setup_ldap_for_failure

    expect(page.status_code).to eq(500)
  end

  def create_account
    visit new_user_session_path
    click_link("Create an account")
    expect(page).to have_current_path(new_user_registration_path)

    # successful account creation
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    fill_in "user_password_confirmation", with: user.password
    click_button("Create Admin")
    expect(page).to have_content("You have signed up successfully")
    click_link("Logout")
  end
end
