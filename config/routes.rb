Rails.application.routes.draw do
  get "sales/index"
  get "payments/new"
  get "payments/create"
  root 'products#index'
  resources :products#, only: [:index, :show]
  resource :cart, only: [:show] do
    post 'add_product/:product_id', to: 'carts#add_product', as: 'add_product'
    delete 'remove_product/:product_id', to: 'carts#remove_product', as: 'remove_product'
    patch 'update_item/:id', to: 'carts#update_item', as: 'update_item'
  end
  resources :sales, only: [:index]
  resources :payments, only: [:new, :create]

  #resources :products, only: [:index, :show]
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  #root to: "home#index"

  #resource :cart, only: [:show] do
  #  post 'add_product/:product_id', to: 'carts#add_product', as: 'add_product'
  #end
  #resources :payments, only: [:new, :create]

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
