Rails.application.routes.draw do

  root 'pages#home'

  get '/dashboard', to: 'users#dashboard'
  get '/users/:id', to: 'users#show'
  get '/selling_orders', to: 'orders#selling_orders'
  get '/buying_orders', to: 'orders#buying_orders'
  put '/orders/:id/complete', to: 'orders#complete', as: 'complete_order'
  get '/all_requests', to: 'requests#list'

  post '/users/edit', to: 'users#update'

  resources :designs do
    member do
      delete :delete_photo
      post :upload_photo
    end
    resources :orders, only: [:create]
  end

  resources :requests

  devise_for :users,
              path: '',
              path_names: {sign_up: 'register',sign_in: 'login',edit: 'profile',sign_out: 'logout'},
              controllers: {registrations:'registrations'}
end
