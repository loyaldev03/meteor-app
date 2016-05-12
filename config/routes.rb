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
      match 'members/update_terms_of_membership' => 'members#update_terms_of_membership', as: 'update_terms_of_membership', :via => [:post]
      match 'members/:id/sale' => 'members#sale', as: 'sale', :via => [:post]
      match 'members/get_banner_by_email' => 'members#get_banner_by_email', as: 'get_banner_by_email', :via => [:post]
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
      put :update_club_role
      put :delete_club_role
    end
  end

  authenticated :agent do
    match "/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]
  end

  scope '/partner/:partner_prefix' do
    resources :clubs do
      match '/test_api_connection' => 'clubs#test_api_connection', :via => :get
    end
    match 'clubs/:client/marketing_tool_attributes' => 'clubs#marketing_tool_attributes', :via => :get

    scope '/club/:club_prefix' do
      match '/users/new' => 'users#new', as: 'new_user', :via => :get
      match '/users' => 'users#index', as: 'users', :via => [:get, :post]
      match '/users/search_result' => 'users#search_result', as: 'users_search_result', :via => [:get]
      
      resources :terms_of_memberships, :path => 'subscription_plans' do
        get :resumed_information
        resources :email_templates, :path => 'communications'
        match '/external_attributes' => 'email_templates#external_attributes', via: :get
        match '/test_communications' => 'email_templates#test_communications', via: [:get, :post] 
      end
      resources :payment_gateway_configurations, :except => [:index, :destroy]
      
      scope '/user/:user_prefix' do
        match '/edit' => 'users#edit', as: 'edit_user', :via => [:get]
        match '/operations' => 'operations#index', as: 'operations', :via => [:post, :get]
        resources :operations, :only => [:show, :update]
        resources :user_notes, :only => [ :new, :create ]
        resources :transactions, :only => [ :index ]
        resources :memberships, :only => [ :index ]
        resources :club_cash_transactions, :only => [:index]
        resources :credit_cards, :only => [ :new, :create, :destroy ] do
          post :activate
        end
        get 'additional_data' => 'users#additional_data'
        post 'additional_data' => 'users#additional_data'
        match '/recover' => 'users#recover', as: 'user_recover', :via => [:get, :post]
        match '/refund/:transaction_id' => 'users#refund', as: 'user_refund', :via => [:get, :post]
        match '/chargeback/:transaction_id' => 'users#chargeback', as: 'user_chargeback', via: [:get, :post]
        match '/full_save' => 'users#full_save', as: 'user_full_save', :via => [:get]
        match '/save_the_sale' => 'users#save_the_sale', as: 'user_save_the_sale', :via => [:get, :post]
        match '/cancel' => 'users#cancel', as: 'user_cancel', :via => [:get, :post]
        match '/blacklist' => 'users#blacklist', as: 'user_blacklist', :via => [:get, :post]
        match '/change_next_bill_date' => 'users#change_next_bill_date', as: 'user_change_next_bill_date', :via => [:get, :post]
        match '/set_undeliverable' => 'users#set_undeliverable', as: 'user_set_undeliverable', :via => [:get, :post]
        match '/set_unreachable' => 'users#set_unreachable', as: 'user_set_unreachable', :via => [:get, :post]
        match '/resend_fulfillment' => 'users#resend_fulfillment', as: 'user_resend_fulfillment', :via => [:post]
        match '/add_club_cash' => 'users#add_club_cash', as: 'user_add_club_cash', :via => :get
        match '/approve' => 'users#approve', as: 'user_approve', :via => [:post]
        match '/reject' => 'users#reject', as: 'user_reject', :via => [:post]  
        match '/no_recurrent_billing' => 'users#no_recurrent_billing', as: 'user_no_recurrent_billing', :via => [:get, :post]  
        match '/manual_billing' => 'users#manual_billing', as: 'user_manual_billing', :via => [:get, :post]
        put '/toggle_testing_account' => 'users#toggle_testing_account', as: 'user_toggle_testing_account'
        match '/' => 'users#show', as: 'show_user', :via => [:get, :post]
        put '/remove_future_tom_change' => 'users#unschedule_future_tom_update', as: 'user_unschedule_future_tom_update'

        post '/sync' => 'users#sync', as: 'user_sync'
        put  '/sync' => 'users#update_sync', as: 'user_update_sync'
        get  '/sync' => 'users#sync_data', as: 'user_sync_data'
        post '/pardot_sync' => 'users#pardot_sync', as: 'user_pardot_sync'
        post '/exact_target_sync' => 'users#exact_target_sync', as: 'user_exact_target_sync'
        post '/mailchimp_sync' => 'users#mailchimp_sync', as: 'user_mailchimp_sync'
        post '/reset_password' => 'users#reset_password', as: 'user_reset_password'
        post '/resend_welcome' => 'users#resend_welcome', as: 'user_resend_welcome'
        get  '/login_as_user' => 'users#login_as_user', as: 'login_as_user'

        get  '/transactions_content' => 'users#transactions_content', as: 'transactions_content'
        get  '/notes_content' => 'users#notes_content', as: 'notes_content'
        get  '/fulfillments_content' => 'users#fulfillments_content', as: 'fulfillments_content'
        get  '/communications_content' => 'users#communications_content', as: 'communications_content'
        get  '/operations_content' => 'users#operations_content', as: 'operations_content'
        get  '/credit_cards_content' => 'users#credit_cards_content', as: 'credit_cards_content'
        get  '/club_cash_transactions_content' => 'users#club_cash_transactions_content', as: 'club_cash_transactions_content'
        get  '/sync_status_content' => 'users#sync_status_content', as: 'sync_status_content'
        get  '/memberships_content' => 'users#memberships_content', as: 'memberships_content'
      end

      resources :products do 
        collection do
          match 'bulk_process' => 'products#bulk_process', via: [:get, :post]
        end
      end
      resources :disposition_types, :except => [ :show, :destroy ]

      match '/fulfillments' => 'fulfillments#index', as: 'fulfillments_index', :via => [:post, :get]
      scope '/fulfillments' do
        get '/files' => 'fulfillments#files', as: 'list_fulfillment_files'
        get '/files/:fulfillment_file_id/check_if_is_in_process' => 'fulfillments#check_if_file_is_in_process', as: 'check_if_file_is_in_process'
        post '/generate_xls' => 'fulfillments#generate_xls', as: 'generate_xls_fulfillments'
        get '/download_xls/:fulfillment_file_id' => 'fulfillments#download_xls', as: 'download_xls_fulfillments'
        get '/list_for_file/:fulfillment_file_id' => 'fulfillments#list_for_file', as: 'fulfillment_list_for_file'
        get '/mark_file_as_sent/:fulfillment_file_id' => 'fulfillments#mark_file_as_sent', as: 'fulfillment_file_mark_as_sent'
      end

      scope '/fulfillment/:id' do
        put '/update_status' => 'fulfillments#update_status', as: 'update_fulfillment_status'
        put '/manual_review' => 'fulfillments#manual_review', as: 'manual_review_fulfillment'
      end

      get '/suspected_fulfillments' => 'fulfillments#suspected_fulfillments', as: 'suspected_fulfillments'
      get '/suspected_fulfillment/:id' => 'fulfillments#suspected_fulfillment_information', as: 'suspected_fulfillment_information'
    end

    resources :domains
    match 'dashboard' => 'admin/partners#dashboard', as: 'admin_partner_dashboard', :via => :get
  end
  match '/users/quick_search' => 'users#quick_search', as: 'users_quick_search', :via => [:get]

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
