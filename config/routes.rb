SacPlatform::Application.routes.draw do
  devise_for :agents

  namespace :api do
    scope 'v1' do
      resources :tokens,:only => [:create]
      match 'tokens/:id' => 'tokens#destroy', as: 'destroy', :via => [:put]
      resources :members, :only => [:create, :show, :update] do
        resources :club_cash_transaction, only: [:create]
        resources :operation, only: [:create]
      end
      match 'members/:id/profile' => 'members#show', as: 'show', :via => [:post]
      match 'members/:id/next_bill_date' => 'members#next_bill_date', as: 'next_bill_date', :via => [:put]
      match 'members/find_all_by_updated/:club_id/:start_date/:end_date' => 'members#find_all_by_updated', as: 'find_all_by_updated', :via => [:post]
      match 'members/find_all_by_created/:club_id/:start_date/:end_date' => 'members#find_all_by_created', as: 'find_all_by_created', :via => [:post]
      match 'members/:id/club_cash' => 'members#club_cash', as: 'club_cash', :via => [:put]
      match 'members/:id/cancel' => 'members#cancel', as: 'cancel', :via => [:put]
      match 'members/:id/change_terms_of_membership' => 'members#change_terms_of_membership', as: 'change_terms_of_membership', :via => [:post]
      match 'members/:id/sale' => 'members#sale', as: 'sale', :via => [:post]
      match '/products/get_stock' => 'products#get_stock', as: 'get_stock', :via => [:get, :post]
      match '/products/get_list_of_stock' => 'products#get_list_of_stock', as: 'get_list_of_stock', :via => [:get, :post]
      resources :prospects, :only => [:create]
    end
  end

  match '/my_clubs' => 'admin/agents#my_clubs', as: 'my_clubs', :via => [:get]

  namespace :admin do
    resources :partners   
    resources :agents do
      get :lock
      get :unlock
    end
    resources :delayed_jobs, :only => [ :index ]
    match '/delayed_jobs/:id/reschedule' => 'delayed_jobs#reschedule', as: 'delayed_job_reschedule', :via => [:post]
  end
  

  scope '/partner/:partner_prefix' do
    resources :clubs do
      match '/test_api_connection' => 'clubs#test_api_connection', :via => :get
    end

    scope '/club/:club_prefix' do
      match '/members/new' => 'members#new', as: 'new_member'
      match '/members' => 'members#index', as: 'members', :via => [:get, :post]
      match '/members/search_result' => 'members#search_result', as: 'members_search_result', :via => [:get]
      
      resources :terms_of_memberships, :path => 'subscription_plans'


      scope '/member/:member_prefix' do
        match '/edit' => 'members#edit', as: 'edit_member', :via => [:get]
        match '/operations' => 'operations#index', as: 'operations', :via => [:post, :get]
        resources :operations, :only => [:show, :update]
        resources :member_notes, :only => [ :new, :create ]
        resources :transactions, :only => [ :index ]
        resources :memberships, :only => [ :index ]
        resources :club_cash_transactions, :only => [:index]
        resources :credit_cards, :only => [ :new, :create, :destroy ] do
          post :activate
        end
        get 'additional_data' => 'members#additional_data'
        post 'additional_data' => 'members#additional_data'
        match '/recover' => 'members#recover', as: 'member_recover', :via => [:get, :post]
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
        match '/no_recurrent_billing' => 'members#no_recurrent_billing', as: 'member_no_recurrent_billing', :via => [:get, :post]  
        match '/manual_billing' => 'members#manual_billing', as: 'member_manual_billing', :via => [:get, :post]
        match '/' => 'members#show', as: 'show_member', :via => [:get, :post]

        post '/sync' => 'members#sync', as: 'member_sync'
        put  '/sync' => 'members#update_sync', as: 'member_update_sync'
        get  '/sync' => 'members#sync_data', as: 'member_sync_data'
        post '/pardot_sync' => 'members#pardot_sync', as: 'member_pardot_sync'
        post '/exact_target_sync' => 'members#exact_target_sync', as: 'member_exact_target_sync'
        post '/reset_password' => 'members#reset_password', as: 'member_reset_password'
        post '/resend_welcome' => 'members#resend_welcome', as: 'member_resend_welcome'
        get  '/login_as_member' => 'members#login_as_member', as: 'login_as_member'

        get  '/transactions_content' => 'members#transactions_content', as: 'transactions_content'
        get  '/notes_content' => 'members#notes_content', as: 'notes_content'
        get  '/fulfillments_content' => 'members#fulfillments_content', as: 'fulfillments_content'
        get  '/communications_content' => 'members#communications_content', as: 'communications_content'
        get  '/operations_content' => 'members#operations_content', as: 'operations_content'
        get  '/credit_cards_content' => 'members#credit_cards_content', as: 'credit_cards_content'
        get  '/club_cash_transactions_content' => 'members#club_cash_transactions_content', as: 'club_cash_transactions_content'
        get  '/sync_status_content' => 'members#sync_status_content', as: 'sync_status_content'
        get  '/memberships_content' => 'members#memberships_content', as: 'memberships_content'
      end

      resources :products
      resources :disposition_types, :except => [ :show, :destroy ]

      match '/fulfillments' => 'fulfillments#index', as: 'fulfillments_index', :via => [:post, :get]
      scope '/fulfillments' do
        get '/files' => 'fulfillments#files', as: 'list_fulfillment_files'
        post '/generate_xls' => 'fulfillments#generate_xls', as: 'generate_xls_fulfillments'
        get '/download_xls/:fulfillment_file_id' => 'fulfillments#download_xls', as: 'download_xls_fulfillments'
        get '/list_for_file/:fulfillment_file_id' => 'fulfillments#list_for_file', as: 'fulfillment_list_for_file'
        get '/mark_file_as_sent/:fulfillment_file_id' => 'fulfillments#mark_file_as_sent', as: 'fulfillment_file_mark_as_sent'
      end

      scope '/fulfillment/:id' do
        put '/update_status' => 'fulfillments#update_status', as: 'update_fulfillment_status'
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
  root :to => 'admin/agents#my_clubs'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
