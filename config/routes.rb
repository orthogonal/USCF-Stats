Uscfstats::Application.routes.draw do
  
  root :to => "interface#index"
  match "/tan_tournaments", :to => "interface#tan_tournaments"
  match "/tan_opponents", :to => "interface#tan_opponents"
  match "/tan_complete", :to => "interface#tan_complete"
  match "/tan_resort", :to => "interface#tan_resort"
  
  match "/upsets", :to => "deltas#index"
  match "/build_chart", :to => "deltas#build_chart"
  match "/rating_history", :to => "deltas#rating_history"
  match "/opp_results", :to => "deltas#opp_results"
  
  match "/performances", :to => "performance#index"
  match "/perf_history", :to => "performance#tournament_history"
  match "/perf_results", :to => "performance#performance_result"
  match "/performance_chart", :to => "performance#build_chart"
  
  match "/matches", :to => "wpw#index"
  match "/tournament_graph", :to => "wpw#build_graph"
  
  match "/experience", :to => "experience#index"

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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
