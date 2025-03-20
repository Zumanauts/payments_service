Rails.application.routes.draw do
  post 'subscription/create'
  # get 'subscription/confirm'
  # get 'subscription/update'
  post 'webhook' => 'webhooks#process_event'

  get 'subscription/test_create'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check


  scope 'internal-api', defaults: { format: 'json' } do
    get 'healtz' => 'health#index'
    get 'subscription/customer_portal_link'

  end
  # Defines the root path route ("/")
  # root "posts#index"
end
