require "rails_helper"

RSpec.describe Settings::DexConnectorOidcsController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    let!(:connector) { create(:dex_connector_oidc, :skip_validation) }

    before do
      get :index
    end

    it "populates an array of oidc dex connectors" do
      expect(assigns(:oidc_connectors)).to match_array([connector])
    end
  end

  describe "GET #new" do
    before do
      get :new
    end

    it "sets data validity to be false" do
      expect(assigns(:is_data_valid)).to be(false)
    end
  end

  describe "GET #edit" do
    let!(:connector) { create(:dex_connector_oidc, :skip_validation) }

    before do
      get :edit, id: connector.id
    end

    it "assigns dex_connector_oidc to @dex_connector_oidc" do
      expect(assigns(:dex_connector_oidc)).not_to be_a_new(DexConnectorOidc)
    end

    it "return 404 if oidc connector does not exist" do
      get :edit, id: DexConnectorOidc.last.id + 1
      expect(response).to have_http_status(:not_found)
    end

  end

  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
  describe "GET #create" do
    good_provider = "http://your.fqdn.here:5556/dex"

    it "fails validation with a bad provider" do
      get :create, validate: true, dex_connector_oidc: {
        name:          "good oidc",
        provider_url:  "dead",
        callback_url:  "http://well.formed.but.invalid/",
        basic_auth:    true,
        client_id:     "client",
        client_secret: "secret"
      }
      expect(response).to render_template("new")
      expect(assigns(:is_data_valid)).to be(false)
    end

    it "passes validation with a good provider" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        get :create, validate: true, dex_connector_oidc: {
          name:          "good oidc",
          provider_url:  good_provider,
          callback_url:  "http://well.formed.but.invalid/",
          basic_auth:    true,
          client_id:     "client",
          client_secret: "secret"
        }
      end
      expect(response).to render_template("new")
      expect(assigns(:is_data_valid)).to be(true)
    end

    it "fails creating with a bad provider" do
      get :create, validate: false, dex_connector_oidc: {
        name:          "good oidc",
        provider_url:  "dead",
        callback_url:  "http://well.formed.but.invalid/",
        basic_auth:    true,
        client_id:     "client",
        client_secret: "secret"
      }
      expect(response).to render_template("new")
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "passes creating with a good provider" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        get :create, validate: false, dex_connector_oidc: {
          name:          "good oidc",
          provider_url:  good_provider,
          callback_url:  "http://well.formed.but.invalid/",
          basic_auth:    true,
          client_id:     "client",
          client_secret: "secret"
        }
      end
      expect(response).not_to have_http_status(:unprocessable_entity)
      expect(response).to redirect_to(settings_dex_connector_oidcs_path)
    end

    context "with rendered views" do
      render_views

      it "shows an error message for empty name" do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          get :create, validate: false, dex_connector_oidc: {
            name:          "",
            provider_url:  good_provider,
            callback_url:  "http://well.formed.but.invalid/", # can't be blank in form
            basic_auth:    true, # also can't be blank - only true/false
            client_id:     "client",
            client_secret: "secret"
          }
        end
        expect(response).to render_template("new")
        expect(response.body).to match(/Name can('|&#39;)t be blank/)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for empty provider" do
        get :create, validate: false, dex_connector_oidc: {
          name:          "good oidc",
          provider_url:  "",
          callback_url:  "http://well.formed.but.invalid/", # can't be blank in form
          basic_auth:    true, # also can't be blank - only true/false
          client_id:     "client",
          client_secret: "secret"
        }
        expect(response).to render_template("new")
        expect(response.body).to match(
          /Provider Url (can('|&#39;)t be blank|is not a valid HTTP URL)/i
        )
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for empty client id" do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          get :create, validate: false, dex_connector_oidc: {
            name:          "good oidc",
            provider_url:  good_provider,
            callback_url:  "http://well.formed.but.invalid/", # can't be blank in form
            basic_auth:    true, # also can't be blank - only true/false
            client_id:     "",
            client_secret: "secret"
          }
        end
        expect(response).to render_template("new")
        expect(response.body).to match(/Client (Id )?can('|&#39;)t be blank/i)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for empty client secret" do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          get :create, validate: false, dex_connector_oidc: {
            name:          "good oidc",
            provider_url:  good_provider,
            callback_url:  "http://well.formed.but.invalid/", # can't be blank in form
            basic_auth:    true, # also can't be blank - only true/false
            client_id:     "client",
            client_secret: ""
          }
        end
        expect(response).to render_template("new")
        expect(response.body).to match(/Client Secret can('|&#39;)t be blank/i)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for non-http issuer entry" do
        get :create, validate: false, dex_connector_oidc: {
          name:          "good oidc",
          provider_url:  "bare.hostname",
          callback_url:  "http://well.formed.but.invalid/",
          basic_auth:    true,
          client_id:     "client",
          client_secret: "secret"
        }
        expect(response).to render_template("new")
        expect(response.body).to match(/is not a valid HTTP URL/)
        expect(response.body).not_to match(/unresolvable hostname|discovery failure|timeout/)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for invalid OIDC issuer hostname" do
        get :create, validate: false, dex_connector_oidc: {
          name:          "good oidc",
          provider_url:  "http://this.fqdn.is.invalid", # RFC 6761
          callback_url:  "http://well.formed.but.invalid/",
          basic_auth:    true,
          client_id:     "client",
          client_secret: "secret"
        }
        expect(response).to render_template("new")
        expect(response.body).to match(/is not a valid OIDC provider/)
        expect(response.body).to match(/unresolvable hostname|discovery failure/)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "shows an error message for mismatched OIDC issuer" do
        VCR.use_cassette("oidc/invalid_connector", allow_playback_repeats: true, record: :none) do
          get :create, validate: false, dex_connector_oidc: {
            name:          "good oidc",
            provider_url:  "http://your.fqdn.here:5556/bad",
            callback_url:  "http://well.formed.but.invalid/",
            basic_auth:    true,
            client_id:     "client",
            client_secret: "secret"
          }
        end
        expect(response).to render_template("new")
        expect(response.body).to match(/is not a valid OIDC provider/)
        expect(response.body).to match(/discovery failure/)
        expect(assigns(:is_data_valid)).to be_falsey
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
  describe "GET #update" do
    good_provider = "http://your.fqdn.here:5556/dex"
    let!(:connector) { create(:dex_connector_oidc, :skip_validation) }

    it "fails validation with a bad provider" do
      get :update, id: connector.id, validate: true,
        dex_connector_oidc: {
          name:          connector.name,
          provider_url:  "dead",
          callback_url:  connector.callback_url,
          basic_auth:    connector.basic_auth,
          client_id:     connector.client_id,
          client_secret: connector.client_secret
        }
      expect(response).to render_template("edit")
      expect(response).to have_http_status(:ok)
      expect(assigns(:is_data_valid)).to be_falsey
    end

    it "passes validation with a good provider" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        get :update, id: connector.id, validate: true,
          dex_connector_oidc: {
            name:          connector.name,
            provider_url:  good_provider,
            callback_url:  connector.callback_url,
            basic_auth:    connector.basic_auth,
            client_id:     connector.client_id,
            client_secret: connector.client_secret
          }
      end
      expect(response).to render_template("edit")
      expect(assigns(:is_data_valid)).to be(true)
    end

    context "with skipped validation" do
      it "refuses updating with a bad provider" do
        get :update, id: connector.id, validate: false,
          dex_connector_oidc: {
            name:          connector.name,
            provider_url:  "dead",
            callback_url:  connector.callback_url,
            basic_auth:    connector.basic_auth,
            client_id:     connector.client_id,
            client_secret: connector.client_secret
          }
        expect(response).to render_template("edit")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(assigns(:is_data_valid)).to be_falsey
      end

      it "passes updating with a good provider" do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          get :update, id: connector.id, validate: false,
            dex_connector_oidc: {
              name:          connector.name,
              provider_url:  good_provider,
              callback_url:  connector.callback_url,
              basic_auth:    connector.basic_auth,
              client_id:     connector.client_id,
              client_secret: connector.client_secret
            }
        end
        expect(response).not_to have_http_status(:unprocessable_entity)
        # expect(subject).to redirect_to([:settings, connector])
        expect(response).to redirect_to([:settings, connector])
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

  describe "POST #create" do
    # rubocop:disable RSpec/ExampleLength
    # TODO: can the post be moved out to a let() and still work?
    it "can not save oidc connector with invalid field" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        expect do
          post :create, dex_connector_oidc: { name: "oidc_fail", invalid_whatevz: nil }
        end.not_to change(DexConnectorOidc, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    # rubocop:enable RSpec/ExampleLength

    context "with oidc connector saved in the database" do
      let!(:connector) do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          post :create, dex_connector_oidc: { name:          "oidc1",
                                              provider_url:  "http://your.fqdn.here:5556/dex",
                                              callback_url:  "http://some.fqdn.here/callback",
                                              basic_auth:    true,
                                              client_id:     "client",
                                              client_secret: "secret_string" }

        end
        DexConnectorOidc.find_by(name: "oidc1")
      end

      it "saves the correct name" do
        expect(connector.name).to eq("oidc1")
      end
      it "saves the correct provider_url" do
        expect(connector.provider_url).to eq("http://your.fqdn.here:5556/dex")
      end
      it "saves the correct callback_url" do
        expect(connector.callback_url).to eq("http://some.fqdn.here/callback")
      end
      it "saves the correct client_id" do
        expect(connector.client_id).to eq("client")
      end
      it "saves the correct client_secret" do
        expect(connector.client_secret).to eq("secret_string")
      end
      it "saves the correct basic_auth value" do
        expect(connector.basic_auth).to eq(true)
      end
    end
  end

  describe "PATCH #update" do
    let!(:connector) { create(:dex_connector_oidc, :skip_validation) }

    it "updates an oidc connector" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        dex_connector_oidc_params = { name: "new name" }
        put :update, id: connector.id, dex_connector_oidc: dex_connector_oidc_params
        expect(DexConnectorOidc.find(connector.id).name).to eq("new name")
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:connector) { create(:dex_connector_oidc, :skip_validation) }

    it "deletes an oidc connector" do
      expect do
        delete :destroy, id: connector.id
      end.to change(DexConnectorOidc, :count).by(-1)
    end
  end
end
