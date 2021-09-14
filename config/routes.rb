Rails.application.routes.draw do

  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"
    get "static_pages/home"
    get "static_pages/about"
    get "static_pages/contact"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"
    get "/search", to: "products#search"
    resources :static_pages

    namespace :admin do
      root "admins#index"
      resources :users, only: %i(index)
    end

    resources :users, except: %i(index destroy)
    resources :categories
    resources :products, only: %i(show)
  end
end
