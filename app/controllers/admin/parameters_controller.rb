class Admin::ParametersController < ApplicationController

  include ApplicationHelper
  layout 'admin'
  before_filter	:authorize, :except => 'login', 
								:role => 'administrator', 
								:msg => 'Access to this page is restricted.'
	
  verify :method => "post", :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

	def solr_replication
		command = params[:command]
		if command
			Parameter.solr_replication(command)
		end
		redirect_to admin_parameters_path
	end

	def replicate_solr
		solr = Parameter.by_name('solr_slave')
		uri = URI.parse("#{solr}/replication?command=fetchindex")
		http = Net::HTTP.new(uri.host, uri.port)
		begin
			response = http.request(Net::HTTP::Get.new(uri.request_uri))
		rescue Errno::EHOSTUNREACH, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED => e
		end
		redirect_to admin_parameters_path
	end

	def mysql_replication
		mysql = params[:mysql]
		command = params[:command]
		unless command.nil? || mysql.nil?
			Parameter.mysql_replication(mysql, command)	
		end
		redirect_to admin_parameters_path
	end

	def switch
		Parameter.switch
		redirect_to admin_parameters_path
	end

  def index
		@parameters = Parameter.all

		@solr_master = Parameter.by_name('solr_master')
		@solr_slave = Parameter.by_name('solr_slave')
		@solr_requests = Parameter.by_name('solr_requests')
		
		@mysql1 = Parameter.by_name('mysql1')
		@mysql2 = Parameter.by_name('mysql2')
		@mysql_requests = Parameter.by_name('mysql_requests')

		@mysql1_state = Parameter.mysql_state('mysql1')
		@mysql2_state = Parameter.mysql_state('mysql2')
		@solr_slave_state = Parameter.solr_state
  end

	def show
		@parameter = Parameter.find(params[:id])
	end

	def new
		@parameter = Parameter.new
	end

	def create
		@parameter = Parameter.new(params[:parameter])
    if @parameter.save
      flash[:notice] = translate('PARAMETER_CREATED')
			redirect_to(:action => "index")
    else
      render :action => 'new'
    end
	end

	def edit
		@parameter = Parameter.find(params[:id])
	end

	def update
		@parameter = Parameter.find(params[:id])
		if @parameter.update_attributes(params[:parameter])
			flash[:notice] = translate('PARAMETER_UPDATED')
			redirect_to :action => 'index'
		else
			render :action => 'edit'
		end

	end

  def destroy
		parameter = Parameter.find(params[:id])
    parameter.destroy
    redirect_to :action => 'index'
  end
  
end
