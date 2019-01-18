# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  get "/autoyast", to: "dashboard#autoyast"

  devise_for :users, controllers: { registrations: "auth/registrations",
                                    sessions:      "auth/sessions" }

  resource :dashboard, only: [:index]
  resource :updates, only: [:create]

  get "/assign_nodes", to: "dashboard#unassigned_nodes"
  post "/assign_nodes", to: "dashboard#assign_nodes"

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "auth/sessions#new"
  end

  get "/autoyast", to: "dashboard#autoyast"
  get "/kubectl-config", to: redirect("/kubeconfig") # deprecated
  get "/kubeconfig", to: "oidc#index"
  get "/_health", to: "health#index"
  post "/update", to: "salt#update"

  get "/oidc", to: "oidc#index"
  get "/oidc/done", to: "oidc#done"
  get "/oidc/kubeconfig", to: "oidc#kubeconfig"

  namespace :orchestrations do
    resource :bootstrap, only: :create, controller: :bootstrap
    resource :upgrade, only: :create, controller: :upgrade
    resource :migration, only: :create, controller: :migration
    namespace :migration do
      post :check, action: :check_mirror
      post :reboot, action: :reboot_nodes
      get :status
    end
  end

  namespace :setup do
    get "/", action: :welcome
    match "/", action: :configure, via: [:put, :patch]
    get  "worker-bootstrap"
    post :build_cloud_cluster
    get :discovery
    post :discovery, action: :set_roles
    get :bootstrap
    post :bootstrap, action: :do_bootstrap
  end

  resources :minions, only: :destroy do
    delete :force, action: :force_destroy, on: :member
    post "accept-minion", to: "salt#accept_minion"
    post "remove-minion", to: "salt#remove_minion"
    post "reject-minion", to: "salt#reject_minion"
  end

  namespace :internal_api, path: "internal-api" do
    namespace :v1 do
      resource :pillar, only: :show
    end
  end

  namespace :settings do
    get "/", action: :index
    resources :registries
    post :apply
    resources :registry_mirrors, path: :mirrors
    resources :kubelet_compute_resources_reservations, only: [:index, :create]
    resources :auditing, only: [:index, :create]
    resources :system_certificates
    resources :ldap_test
    resources :dex_connector_ldaps, path: :ldap_connectors
    resources :dex_connector_oidcs, path: :oidc_connectors
    resources :external_cert, only: [:index, :create]
  end
end
# rubocop:enable Metrics/BlockLength
