Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
  devise_for :members, path: "member", controllers: {
    sessions: "members/sessions",
    passwords: "members/passwords"
  }

  # Member self-service portal
  namespace :portal do
    root to: "dashboard#show"
  end

  resources :members
  resources :attendances do
    collection do
      get  :bulk_new
      post :bulk_create
    end
  end
  resources :charges
  resources :payments
  resources :expenses

  # Reports are plain scoped queries served at /reports/attendance, /balances, /treasury.
  get "reports/attendance", to: "reports#attendance", as: :attendance_report
  get "reports/balances",   to: "reports#balances",   as: :balances_report
  get "reports/treasury",   to: "reports#treasury",   as: :treasury_report

  root to: "dashboard#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
