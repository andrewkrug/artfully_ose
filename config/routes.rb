Rails.application.routes.draw do

  namespace :mobile do
    resources :users, :only => [] do
      collection do
        post :sign_in
      end
    end
    resource :dashboard, :only => :show, :controller => :dashboard
    resources :organizations, :only => [] do
      resources :events, :only => :index
    end
    resources :events, :only => [:index] do
      resources :shows, :only => :index
    end
    resources :shows, :only => [:index, :show] do
      resources :orders, :only => :index
    end
    resources :orders, :only => [:index, :show] do
      collection { post :validate }
      member { post :validate }
    end
    resources :tickets, :only => [:show] do
      collection do
        post :validate
        post :unvalidate
      end
      member do
        post :validate
        post :unvalidate
        get :order
      end
    end
  end

  namespace :api do
    resources :events, :only => :show
    resources :tickets, :only => :index
    resources :shows, :only => :show
    resources :organizations, :only => [] do
      resources :events
      resources :shows
      get :authorization
    end
  end

  scope ':organization_slug' do
    namespace :store do
      resources :events, :only => [:show, :index]
      resources :memberships, :only => [:show, :index]
      resources :passes, :only => [:show, :index]
      resources :rolling_membership_types,  :controller => :membership_types
      resources :seasonal_membership_types, :controller => :membership_types
      resources :shows, :only => :show
      resource  :checkout, :only => :create
      resources :retrievals, :only => [:index, :create]

      resource :order, :only => :destroy
      get "order", :to => "orders#show"
      post "order", :to => "orders#update"

      get "donate",       :to => "donations#index"
    end
  end

  #legacy for now to support the old routes directly to events and shows
  namespace :store do
    resources :events, :only => :show, :as => :old_storefront_event
    resources :shows, :only => :show
    # resource :checkout, :only => :create
    resource  :checkout, :only => :create do
      get "dook", :to => "checkouts#dook"
    end
  end

  devise_for :members, :controllers => { :invitations => "members/invitations", :passwords => "members/passwords", :sessions => "members/sessions"}
  devise_for :users, :controllers => {:sessions => "users/sessions"}
  devise_scope :user do
    get "sign_up", :to => "devise/registrations#new"
  end

  namespace :members do
    root :to => "index#index"
    resources :people, :only => :update
  end

  resources :organizations do
    put :tax_info, :on => :member
    resources :user_memberships
    member do
      post :connect
    end
  end

  resources :ticket_offers do
    collection do
      post "/new", :to => "ticket_offers#new"
      get "/create", :to => "ticket_offers#create"
    end
    member do
      get :accept
      get :decline
    end
  end

  resources :export do
    collection do
      get :contacts
      get :donations
      get :ticket_sales
    end
  end

  resources :kits, :except => :index do
    get :alternatives, :on => :collection
    post :requirements, :on => :collection
    get :requirements, :on => :collection
  end

  resources :membership_kits, :only => [ :edit, :update ]
  resources :passes_kits, :only => [ :edit, :update ]
  resources :passes_reports, :only => [:index]

  resources :regular_donation_kits, :only => [ :edit, :update ]

  resources :reports, :only => :index
  resources :statements, :only => [ :index, :show ] do
    resources :slices, :only => [ :index ] do
      collection do
        get :data
      end
    end
  end

  def people_actions
    resources :actions
    resources :passes, :only => [:index] do
      collection do
        post :bulk_update
        post :reminder
      end
    end   
    
    resources :relationships, :only => :index
    resources :memberships do
      collection do
        post :bulk_update
      end
    end

    member do
      post :reset_password
    end
    resources :membership_comps, :only => :new
    resources :membership_cancellations, :only => [:new, :create]
    resources :membership_changes, :only => :create

    ["get_action",
     "change_action",
     "refund_action",
     "join_action",
     "hear_action",
     "say_action",
     "do_action",
     "go_action",
     "give_action"].each { |action_type| resources :actions, :as => action_type }

    resources :notes
    resources :phones, :only => [:create, :destroy]
    resource  :address, :only => [:create, :update, :destroy]

    post 'star/:type/:action_id' => 'people#star', :as => :star
    post 'tag' => 'people#tag', :as => :new_tag
    delete 'tag/:tag' => 'people#untag', :as => :untag
  end

  resources :people do
    people_actions
  end
  resources :individuals, :controller => :people do
    people_actions
  end
  resources :companies, :controller => :people do
    people_actions
  end

  resources :households do
    collection do
      get :suggested
      put "suggested/:suggested_id" => "households#ignore_suggested", :as => "ignore_suggested"
    end
  end

  def shared_search_segment_routes
    resources :actions, :only => [:new, :create]
    resources :membership_comps, :only => :new

    member do
      post :tag
    end
  end

  resources :searches, :only => [:new, :create, :show] do
    shared_search_segment_routes

    collection do
      get "/create", :to => "searches#create"
    end
  end
  resources :segments, :only => [:index, :show, :create, :destroy] do
    shared_search_segment_routes
  end

  resources :console_sales do
    collection do
      get  "/events/:event_id", :action => :events
      get  "/shows/:show_id", :action => :shows
    end
  end

  resources :events do
    member do
      get :widget
      get :storefront_link
      get :resell
      get :wp_plugin
      get :prices
      get :image
      get :messages
    end
    resources :discounts
    resources :events_pass_types
    resources :shows do
      resource :sales, :only => [:new, :create, :show, :update] do
        get :door_list, :on => :collection
      end
      member do
        get :door_list
        post :published
        post :unpublished
        post :on_sale
        post :off_sale
      end
      collection do
        get  :calendar
        get  :upcoming
        get  "/:year/:month", :as => :monthly, :action => :index
      end
    end
    resource :venue, :only => [:edit, :update]
  end

  resources :shows, :only => [] do
    resources :tickets, shallow: true, :only => [ :new, :create ] do
      member do
        put :validated
        put :unvalidated
      end

      collection do
        delete :delete
        put :on_sale
        put :off_sale
        put :bulk_edit
        put :change_prices
        get :set_new_price
      end
    end
  end

  resources :charts, :only => [:update] do
    resources :sections
  end

  resources :sections do
    resources :ticket_types, :only => [:new, :create]
    collection do
      post :on_sale
      post :off_sale
    end
  end

  resources :ticket_types, :only => [:edit, :update]

  resources :orders do
    resource :assignment, :only => [ :new, :create ]
    collection do
      get :membership
      get :passes
      get :sales
    end
    member do
      get :resend
    end
  end

  resources :contributions

  resources :refunds, :only => [ :new, :create ]
  resources :exchanges, :only => [ :new, :create ]
  resources :returns, :only => :create
  resources :merges, :only => [ :new, :create ]
  resources :pass_types
  resources :membership_types
  resources :rolling_membership_types,  :controller => :membership_types
  resources :seasonal_membership_types, :controller => :membership_types
  resources :membership_comps, :only => :create
  resources :member_cards, :only => :new

  resources :imports do
    member do
      get :approve
      get :recall
    end
    collection do
      get :template
    end
  end

  resources :discounts_reports, :only => [:index]

  match '/recent_activity' => 'index#recent_activity', :as => :recent_activity
  match '/events/:event_id/charts/' => 'events#assign', :as => :assign_chart, :via => "post"
  match '/dashboard' => 'index#dashboard', :constraints => lambda{|r| r.env["warden"].authenticate?}
  match ':organization_slug/whats-my-pass', :controller => 'store/retrievals', :action => 'index'

  get ':organization_slug/:controller(/:action(/:id))', controller: /store\/[^\/]+/
  match '/:organization_slug' => 'store/events#index', :as => :store_organization_events

  root :to => 'index#dashboard'

end
