# frozen_string_literal: true
Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "auth/registrations",
                                    sessions:      "auth/sessions" }

  resource :dashboard, only: [:index]

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "auth/sessions#new"
  end

  get "/autoyast", to: "dashboard#autoyast"
  get "/kubectl-config", to: "dashboard#kubectl_config"

  namespace :setup do
    get "/", action: :welcome
    match "/", action: :configure, via: [:put, :patch]
    get :"worker-bootstrap"
    get :discovery
    post :bootstrap
  end
end
