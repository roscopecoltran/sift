class Admin::ThemesReferencesController < ApplicationController

  include ApplicationHelper
  layout 'admin'
  before_filter	:authorize, :except => 'login', 
								:role => 'administrator', 
								:msg => 'Access to this page is restricted.'
	before_filter :define_list, :only => [:index, :list]
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :create, :update_all ],
         :redirect_to => { :action => :index }

	def define_list
		@source = params[:source].nil? ? 'portfoliodw' : params[:source]
		@list = @source == 'portfoliodw' ? 'list_portfolio' : 'list_bdm'
	end

	def list
		render :partial => @list
	end

	def new
		@ref = ThemesReference.new
		@ref.source = params[:source]
		@ref.ref_theme = params[:theme] unless params[:theme].nil?
	end

	def create
		@ref = ThemesReference.new(params[:themes_reference])
		if @ref.save
			redirect_to admin_themes_references_path(:source => @ref.source)
		else
			render :action => 'new'
		end 
	end

	def edit
		@theme = params[:theme]
		@source = params[:source]
		@references = ThemesReference.all_by_theme_and_source(@theme, @source)
	end

	def update_all
		params[:references].each do |ref|
			if ref[1].keys.include?('del')
				params[:references] = params[:references].reject {|r| r == ref}
				ref = ThemesReference.find(ref[0])
				ref.destroy
			end
		end
		@references = ThemesReference.update(params[:references].keys, params[:references].values).reject {|th| th.errors.empty?}
		@source = params[:source]
		if @references.empty?
			flash[:notice] = "Mappings mis à jour"
			redirect_to admin_themes_references_path(:source => @source) 
		else
			@theme = params[:theme]
			render :action => 'edit' 
		end
	end

	def destroy_all
		references = ThemesReference.all_by_theme_and_source(params[:theme], params[:source])
		references.each do |ref|
			ref.destroy
		end
		redirect_to admin_themes_references_path(:source => params[:source]) 
	end
  
end
