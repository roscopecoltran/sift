# $Id: routes.rb 493 2006-10-25 15:57:02Z dchud $

ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
	map.connect ':controller/service.wsdl', :action => 'wsdl'

	# Install the default route as the lowest priority.
	map.connect ':controller/:action/:id/'
	map.connect '', :controller => "record", :action => 'search'
	map.connect 'admin', :controller => 'admin/dashboard', :action => 'index'
	map.connect 'switch', :controller => 'application', :action => 'switch'
	map.resources :admin
	map.namespace :admin do |admin|
		admin.resources :parameters, :collection => { :solr_replication => :get, :mysql_replication => :get, :switch => :get, :replicate_solr => :get }
		admin.resources :collections
		admin.resources :collection_groups
		admin.resources :coverages
		admin.resources :docstat
		admin.resources :document_types
		admin.resources :editorials, :collection => { :affecte => :get }
		admin.resources :harvest_schedules, :collection => { :display_log => :get }
		admin.resources :manage_roles
		admin.resources :manage_droits
		admin.resources :primary_document_types
		admin.resources :providers
		admin.resources :rejects
		admin.resources	:exports, :collection => { :crawler => :get, :groups => :get, :themes => :get }
		admin.resources :rss_feeds
		admin.resources :search_tab_filters
		admin.resources :search_tab_subjects
		admin.resources :search_tabs
		admin.resources :themes
		admin.resources :themes_references, :collection => { :destroy_all => :get, :update_all => :put }
		admin.resources :users
	end

end
