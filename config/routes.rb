SampleApp::Application.routes.draw do

  resources :users do
    member do
      get 'show'
      post 'create'
      put 'create'
    end
    collection do
    end
  end

  match '/users', :to => 'users#new'
  match '/search', :to => 'users#new'
  root :to => "users#new"
  
  match '/about', :to   => 'pages#about'

end
