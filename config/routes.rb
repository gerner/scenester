Events::Application.routes.draw do
  match "events/foursquare" => "events#foursquare"
  resources :events do
    post 'recommend', :on => :member, :action => 'recommend'
    delete 'recommend', :on => :member, :action => 'unrecommend'
    get 'partial', :on => :member, :action => 'show_partial'
  end
  match "music", :to => "events#nav_music"
  match "tech", :to => "events#nav_tech"
  match "art", :to => "events#nav_art"
  match "film", :to => "events#nav_film"
  match "theater", :to => "events#nav_theater"
  #match "events/:id/recommend", :to => "events#recommend", :via => :post
  #match "events/:id/recommend", :to => "events#unrecommend", :via => :delete
  resources :venues

  match "blog" => "blog#show"
  match "blog/:cat/:title", :to => "blog#show" 

  get "home/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  #root :to => "home#index"
  root :to => "events#index"
  match "search" => "events"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  # setup for oauth callbacks and sessions
  match '/auth/:provider/callback', :to => 'sessions#create'
  match '/profile', :to => 'sessions#show'
  match '/login', :to => 'sessions#new' 
  match '/logout', :to => 'sessions#destroy'
end
