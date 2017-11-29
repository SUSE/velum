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
  get "/kubectl-config", to: "oidc#index"
  get "/_health", to: "health#index"
  post "/update", to: "salt#update"
  post "/accept-minion", to: "salt#accept_minion"

  get "/oidc", to: "oidc#index"
  get "/oidc/done", to: "oidc#done"
  get "/oidc/kubeconfig", to: "oidc#kubeconfig"

  resource :orchestration, only: [:create]

  namespace :setup do
    get "/", action: :welcome
    match "/", action: :configure, via: [:put, :patch]
    get :"worker-bootstrap"
    get :discovery
    post :discovery, action: :set_roles
    get :bootstrap
    post :bootstrap, action: :do_bootstrap
  end

  namespace :internal_api, path: "internal-api" do
    namespace :v1 do
      resource :pillar, only: :show
    end
  end
end
# rubocop:enable Metrics/BlockLength
