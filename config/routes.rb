SacPlatform::Application.routes.draw do
  devise_for :agents

  namespace :api do
    scope 'v1' do
      resources :tokens,:only => [:create, :destroy]
      resources :members, :only => [:create, :show, :update] do
        resources :club_cash, only: :create
      end
      match '/get_stock' => 'products#get_stock', as: 'get_stock', :via => [:get]
      resources :prospects, :only => [:create]      
    end
  end

  namespace :admin do
    resources :partners   
    resources :agents do
      get :lock
      get :unlock
      get :my_clubs
    end
  end

  scope '/partner/:partner_prefix' do
    resources :clubs

    scope '/club/:club_prefix' do
      match '/members/new' => 'members#new', as: 'new_member'
      match '/members' => 'members#index', as: 'members', :via => [:get, :post]
      match '/members/search_result' => 'members#search_result', as: 'members_search_result', :via => [:get]

      scope '/member/:member_prefix' do
        match '/edit' => 'members#edit', as: 'edit_member', :via => [:get]
        match '/operations' => 'operations#index', as: 'operations', :via => [:post, :get]
        resources :operations, :only => [:show, :update]
        resources :member_notes, :only => [ :new, :create ]
        resources :terms_of_memberships, :only => [ :show ]
        resources :transactions, :only => [ :index ]
        resources :credit_cards, :only => [ :new, :create ] do
          post :activate
          post :set_as_blacklisted
          post :unset_blacklisted
        end
        match '/recover' => 'members#recover', as: 'member_recover', :via => [:post]
        match '/refund/:transaction_id' => 'members#refund', as: 'member_refund', :via => [:get, :post]
        match '/full_save' => 'members#full_save', as: 'member_full_save', :via => [:get]
        match '/save_the_sale' => 'members#save_the_sale', as: 'member_save_the_sale', :via => [:get, :post]
        match '/cancel' => 'members#cancel', as: 'member_cancel', :via => [:get, :post]
        match '/blacklist' => 'members#blacklist', as: 'member_blacklist', :via => [:get, :post]
        match '/change_next_bill_date' => 'members#change_next_bill_date', as: 'member_change_next_bill_date', :via => [:get, :post]
        match '/set_undeliverable' => 'members#set_undeliverable', as: 'member_set_undeliverable', :via => [:get, :post]
        match '/set_unreachable' => 'members#set_unreachable', as: 'member_set_unreachable', :via => [:get, :post]
        match '/resend_fulfillment' => 'members#resend_fulfillment', as: 'member_resend_fulfillment', :via => [:post]
        match '/add_club_cash' => 'members#add_club_cash', as: 'member_add_club_cash'
        match '/approve' => 'members#approve', as: 'member_approve', :via => [:post]
        match '/reject' => 'members#reject', as: 'member_reject', :via => [:post]  
        match '/login_as_member' => 'members#login_as_member', as: 'login_as_member', :via => [:get]  
        match '/' => 'members#show', as: 'show_member', :via => [:get, :post]
      end
      resources :products     
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
