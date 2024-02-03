Rails.application.routes.draw do
  get 'blue_shift_boards/show'

  authenticated :user, -> user { user.t1_role == "admin" } do
    mount Delayed::Web::Engine, at: '/jobs'
  end

  devise_for :users
  mount Commontator::Engine => '/commontator'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'metrics#index'
  post 'metrics.json' => 'metrics#index'
  post 'toggle_team_ui' => 'metrics#toggle_team_ui'
  resources :metrics do
    resources :metric_charts, only: [:index]
  end

  post 'email_imports' => 'email_imports#create'
  resources :properties do
    member do 
      post 'send_test_message_to_slack'
      get 'latest_inspection_partial', to: "properties#latest_inspection_partial"
      get 'latest_inspection_and_deficients_partial', to: "properties#latest_inspection_and_deficients_partial"
      get 'bluesky_stats_partial', to: "properties#bluesky_stats_partial"
    end
    resources :blue_shifts do
      member do 
        patch 'archive'
      end
    end
    resources :maint_blue_shifts do
      member do 
        patch 'archive'
      end
    end
    resources :trm_blue_shifts do
      member do 
        patch 'archive'
      end
    end
    # resources :property_units, only: [:show]
  end 

  get 'trm_blueshift_metrics' => 'trm_blueshift_metrics#show', as: 'trm_blueshift_metrics'

  resources :teams do
    member do 
      post 'send_test_message_to_slack'
    end
    resources :blue_shifts do
      member do 
        patch 'archive'
      end
    end
    resources :maint_blue_shifts do
      member do 
        patch 'archive'
      end
    end
    resources :trm_blue_shifts do
      member do 
        patch 'archive'
      end
    end
  end

  resources :users do
    member do 
      patch 'reset_password'
    end
  end

  post 'email_csv_imports' => 'email_csv_imports#create'

  post 'metric_attribute_charts' => 'metric_attribute_charts#show', as: 'metric_attribute_charts'
  get 'property_charts' => 'property_charts#show', as: 'property_charts'

  get 'rent_change_reasons' => 'rent_change_reasons#show', as: 'rent_change_reasons'
  get 'conversions_for_agents' => 'conversions_for_agents#show', as: 'conversions_for_agents'
  get 'conversions_for_agents_charts' => 'conversions_for_agents_charts#show', as: 'conversions_for_agents_charts'
  get 'cfa_charts.json' => 'cfa_charts#index'
  get 'conversions_for_properties' => 'conversions_for_properties#show', as: 'conversions_for_properties'
  get 'unit_type_rent_history' => 'unit_type_rent_history#show', as: 'unit_type_rent_history'
  
  get 'compliance_issues' => 'compliance_issues#show', as: 'compliance_issues'

  get 'bluebot_rollup_report' => 'bluebot_rollup_report#show', as: 'bluebot_rollup_report'
  get 'bluebot_agent_sales_rollup_report' => 'bluebot_agent_sales_rollup_report#show', as: 'bluebot_agent_sales_rollup_report'

  get 'incomplete_work_orders' => 'incomplete_work_orders#show', as: 'incomplete_work_orders'

  get 'renewals_unknown_details' => 'renewals_unknown_details#show', as: 'renewals_unknown_details'
  get 'collections_non_eviction_past20_details' => 'collections_non_eviction_past20_details#show', as: 'collections_non_eviction_past20_details'

  get 'costar_market_data' => 'costar_market_data#show', as: 'costar_market_data'

  get 'collections_details' => 'collections_details#show', as: 'collections_details'
  resources :collections_details do
    resources :collections_detail_charts, only: [:index]
  end

  get 'collections_by_tenant_details' => 'collections_by_tenant_details#show', as: 'collections_by_tenant_details'
  get 'collections_by_tenant_details/json_api(:format)' => 'collections_by_tenant_details#json_api'

  get 'blue_shift_boards' => 'blue_shift_boards#show', as: 'blue_shift_boards'

  get 'recruiting' => 'workable_jobs#index', as: 'workable_jobs'
  resources :workable_jobs, only: [:show, :edit, :update]

  post 'workable_jobs_export' => 'workable_jobs_export#index'

  get 'property_units' => 'property_units#show', as: 'property_units'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
