class Admin::ThemesController < ApplicationController

  include ApplicationHelper
  layout 'admin'
  before_filter	:authorize, :except => 'login', 
								:role => 'administrator', 
								:msg => 'Access to this page is restricted.'
	
	before_filter :load_roots, :only => [:new, :edit, :create, :update]
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }
  
  def index
		@themes = Theme.roots
  end

	def load_roots
		@roots = Theme.roots.collect {|root| [root.label, root.reference.to_i]}
		@roots << ['Aucun parent', 0]
		@roots = @roots.sort_by { |root| root[1] }
	end

	def new
		@theme = Theme.new
		unless params[:parent].nil?
			@theme.parent = params[:parent] 
			@theme.reference = params[:parent] 
		end
	end

	def create
		@theme = Theme.new(params[:theme])
    if @theme.save
      flash[:notice] = translate('THEME_CREATED')
			redirect_to(:action => "index")
    else
      render :action => 'new'
    end
	end

	def edit
		@theme = Theme.find(params[:id])
	end

	def update
		@theme = Theme.find(params[:id])
		if @theme.update_attributes(params[:theme])
			flash[:notice] = translate('THEME_UPDATED')
			redirect_to :action => 'index'
		else
			render :action => 'edit'
		end

	end

  def destroy
		theme = Theme.find(params[:id])
		Theme.delete_all("parent = #{theme.reference.to_i}")
		ThemesReference.delete_all("ref_theme = #{theme.reference.to_i}")
		ThemesReference.delete_all("exclusion = #{theme.reference.to_i}")
    theme.destroy
    redirect_to :action => 'index'
  end
  
end
