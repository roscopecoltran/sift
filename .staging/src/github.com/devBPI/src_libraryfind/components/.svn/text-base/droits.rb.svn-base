class CreateDroit
  
	ENV['LIBRARYFIND_HOME'] = ENV['LIBRARYFIND_HOME'].nil? ? "../" : ENV['LIBRARYFIND_HOME']
  
	require 'rubygems'
	require 'yaml'
	require 'iconv'
	require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
	require ENV['LIBRARYFIND_HOME'] + 'app/models/manage_droit'

	RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
  
	# Database connexion
	def initialize
		@db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")
		@dbtype = 'production'
    
		if defined? @db[@dbtype]["port"]
			ActiveRecord::Base.establish_connection(
				:adapter => @db[@dbtype]["adapter"],
				:host => @db[@dbtype]["host"],
				:username => @db[@dbtype]["username"],
				:password => @db[@dbtype]["password"],
				:database => @db[@dbtype]["database"]
			)
		else
			ActiveRecord::Base.establish_connection(
				:adapter => @db[@dbtype]["adapter"],
				:host => @db[@dbtype]["host"],
				:username => @db[@dbtype]["username"],
				:password => @db[@dbtype]["password"],
				:database => @db[@dbtype]["database"],
				:port => @db[@dbtype]["port"]
			)
		end
	end

  def externes
		droits = ManageDroit.find(:all, :conditions => "id_lieu = 'GENERALITES'")
		droits.each do |d|
			new_droit = ManageDroit.new
			new_droit.id_perm = d.id_perm
			new_droit.id_role = d.id_role
			new_droit.id_lieu = "EXTERNE"
			new_droit.id_collection = d.id_collection
			new_droit.save!
		end
  end

  def pros
		droits = ManageDroit.find(:all, :conditions => "id_lieu = 'GENERALITES'")
		droits.each do |d|
			new_droit = ManageDroit.new
			new_droit.id_perm = d.id_perm
			new_droit.id_role = d.id_role
			new_droit.id_lieu = "PRO"
			new_droit.id_collection = d.id_collection
			new_droit.save!
		end
  end

end

runner = CreateDroit.new
runner.externes
runner.pros
