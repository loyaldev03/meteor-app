SacPlatform::Application.routes.draw do
  devise_for :agents

  namespace :api do
    scope 'v1' do
      match 'enroll' => 'members#enroll', as: 'v1_enroll_members', :via => :post
      match 'update_profile/:id/:club_id' => 'members#update_profile', as: 'v1_update_profile_members', :via => :put
    end
  end

  namespace :admin do
    resources :partners   
    resources :agents do
      get :lock
      get :unlock
    end
  end

  scope '/partner/:partner_prefix' do
    resources :clubs
    scope '/club/:club_prefix' do
      match '/members/new' => 'members#new', as: 'new_member'
      match '/members' => 'members#index', as: 'members', :via => [:get, :post]
      scope '/member/:member_prefix' do
        match '/edit' => 'members#edit', as: 'edit_member', :via => [:get]
        resources :operations, :only => [ :show, :update ]
        resources :member_notes, :only => [ :new, :create ]
        resources :credit_cards, :only => [ :new, :create ] do
          post :activate
          post :set_as_blacklisted
        end
        match '/recover' => 'members#recover', as: 'member_recover', :via => [:post]
        match '/refund/:transaction_id' => 'members#refund', as: 'member_refund', :via => [:get, :post]
        match '/full_save' => 'members#full_save', as: 'member_full_save', :via => [:get]
        match '/save_the_sale' => 'members#save_the_sale', as: 'member_save_the_sale', :via => [:get, :post]
        match '/cancel' => 'members#cancel', as: 'member_cancel', :via => [:get, :post]
        match '/blacklist' => 'members#blacklist', as: 'member_blacklist', :via => [:get, :post]
        match '/change_next_bill_date' => 'members#change_next_bill_date', as: 'member_change_next_bill_date', :via => [:get, :post]
        match '/' => 'members#show', as: 'show_member', :via => [:get, :post]
      end
    end
    resources :domains
    match 'dashboard' => 'admin/partners#dashboard', as: 'admin_partner_dashboard'
  end



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
  root :to => 'admin/partners#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
