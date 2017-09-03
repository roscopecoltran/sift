class Parameter < ActiveRecord::Base

	def self.by_name(name)
		param = find_by_name(name)
		param = param.nil? ? name.upcase.constantize : param.value.strip
	end

	def self.switch
		mysql1 = by_name('mysql1')
		mysql2 = by_name('mysql2')
		old_mysql_requests = by_name('mysql_requests')
		new_mysql_requests = old_mysql_requests == mysql1 ? mysql2 : mysql1

		solr_master = by_name('solr_master')
		solr_slave = by_name('solr_slave')
		old_solr_requests = by_name('solr_requests')
		new_solr_requests = old_solr_requests == solr_master ? solr_slave : solr_master

		solr_replication('disable')
		mysql_replication(mysql1, 'stop')
		mysql_replication(mysql2, 'stop')

		db = mysql_db_infos
		db[:host] = new_mysql_requests

		msg = "Mysql switched to #{new_mysql_requests} and solr switched to #{new_solr_requests}"
	
		begin
			Parameter.update_all("value = '#{new_mysql_requests}'", "name = 'mysql_requests'")
			Parameter.update_all("value = '#{new_solr_requests}'", "name = 'solr_requests'")
			ActiveRecord::Base.establish_connection(db)
			Parameter.update_all("value = '#{new_mysql_requests}'", "name = 'mysql_requests'")
			Parameter.update_all("value = '#{new_solr_requests}'", "name = 'solr_requests'")
		rescue Exception => e
			msg = "Couldn't switch to solr #{new_solr_requests} and mysql #{new_mysql_requests} => #{e.message}"
			logger.info msg
			db[:host] = old_mysql_requests
			Parameter.update_all("value = '#{old_mysql_requests}'", "name = 'mysql_requests'")
			Parameter.update_all("value = '#{old_solr_requests}'", "name = 'solr_requests'")
			ActiveRecord::Base.establish_connection(db)
			Parameter.update_all("value = '#{old_mysql_requests}'", "name = 'mysql_requests'")
			Parameter.update_all("value = '#{old_solr_requests}'", "name = 'solr_requests'")
		end
		msg
	end

	######### Mysql replication ###################################
	def self.mysql_db_infos
		file = YAML::load_file("#{Rails.root}/config/database.yml")
		db = { 
			:adapter  => file[RAILS_ENV]['adapter'],
			:host     => file[RAILS_ENV]['host'],
			:user 		=> file[RAILS_ENV]['username'],
			:password => file[RAILS_ENV]['password'],
			:database => file[RAILS_ENV]['database'],
		}   
		return db
	end

	require 'dbi'
	def self.mysql_state(mysql)
		state = init_state('on', 'mysql')
		db = mysql_db_infos
		uri = "DBI:Mysql:#{db[:database]};host=#{by_name(mysql)}"
		begin
			conn = DBI.connect(uri, db[:user], db[:password])
			r = conn.select_one('show slave status')
			if r["Slave_IO_Running"] == "No" || r["Slave_SQL_Running"] == "No"
				state = init_state('off', 'mysql')
				errors =  %w{Last_Error Last_IO_Error Last_SQL_Error}.collect { |err| r[err] }.uniq!.join(" ")
				state[:status] += " (Erreur: #{errors})" unless errors.empty?
			end
		rescue Exception => e
			logger.info "Couldn't get mysql state: #{e}"
			state = init_state('off', 'mysql')
		end
		state
	end

	def self.mysql_replication(mysql, command)
		msg = "[Portfolio_harvester] Mysql replication (#{mysql}) successfully #{command.pluralize}"
		begin
			db = mysql_db_infos
			uri = "DBI:Mysql:#{db[:database]};host=#{mysql}"
			conn = DBI.connect(uri, db[:user], db[:password])
			r = conn.do("#{command} slave")
		rescue Exception => e
			msg = "[Portfolio_harvester] Failed to #{command} replication for mysql host #{mysql.pluralize} => #{e.message}"
			logger.info msg
		end
		return msg
	end

	######### Solr replication ###################################

	def self.solr_state
		ip = by_name('solr_slave')
		url = "#{ip}/replication?command=details"
		begin
			doc = Nokogiri::HTML(open(url, :proxy => 'http://10.1.2.30:3128'))
			slavenode = Nokogiri::XML((doc.search("lst[@name='slave']")).to_xml)
			state = init_state('on', 'solr')
			unless slavenode.nil?
				disabled = slavenode.search("str[@name='isPollingDisabled']").first.text
				isReplicating = slavenode.search("str[@name='isReplicating']").first.text
				error = slavenode.search("str[@name='ERROR']").first
				if !error.nil?
					state = init_state('off', 'solr')
					state[:status] += " (Erreur: #{error.text}) "
				elsif disabled == 'true' 
					state = init_state('off', 'solr')
				elsif isReplicating == 'true'
					state = init_state('in_progress', 'solr')
				end
			end
		rescue Exception => e
			logger.info "Couldn't get solr state: #{e}"
			state = init_state('off', 'solr')
		end
		state
	end

	def self.solr_replication(command)
		solr = Parameter.by_name('solr_slave')
		uri = URI.parse("#{solr}/replication?command=#{command}poll")
		http = Net::HTTP.new(uri.host, uri.port)
		msg = "[Portfolio_harvester] Solr replication (#{solr}) successfully #{command}d"
		begin
			response = http.request(Net::HTTP::Get.new(uri.request_uri))
		rescue Errno::EHOSTUNREACH, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED => e
			msg =  "[Portfolio_harvester] Failed to #{command} solr replication (#{solr}) => #{e.message}"
			logger.info msg
		end
		msg
	end

	##############################################################################

	def self.init_state(action, type)
		state = Hash.new
		case action
			when 'on' then
				state[:status] = 'Réplication active'
				state[:color] = 'green'
				state[:action] = 'Désactiver la réplication'
				state[:action_link] = "#{type}_replication_admin_parameters_path"
				state[:command] = type == 'solr' ? 'disable' : 'stop'
			when 'off' then
				state[:status] = 'Réplication désactivée'
				state[:color] = 'red'
				state[:action] = 'Activer la réplication'
				state[:action_link] = "#{type}_replication_admin_parameters_path"
				state[:command] =  type == 'solr' ? 'enable' : 'start'
			when 'in_progress' then
				state[:status] = "En cours de réplication"
				state[:color] = ""
				state[:action] = ""
				state[:action_link] = ""
				state[:command] = ""
		end
		state
	end

end
