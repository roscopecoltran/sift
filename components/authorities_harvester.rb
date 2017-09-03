require 'common_harvester'
require 'net/http'
require 'uri'
require 'dbi'

class AuthoritiesHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def harvest(collection_id, partial_harvesting)

    total_time_start = Time.now
    @logger.info("[authorities_harvester] DATABASE INFO: #{@db["database"]}")
    begin
			# Initialize portfolio informations and DBI connection
      collection = Collection.find_by_id(collection_id)
      last_harvest = collection.harvested
			last_harvest_msg = "[authorities_harvester] The last harvest failed" 
			last_harvest_msg = "[authorities_harvester] The last harvest was the #{last_harvest.strftime("%d/%m/%Y at %H:%M")}" unless last_harvest.nil?
      uri = "DBI:Pg:database=portfoliodw;host=#{collection.host}"
      @conn = DBI.connect(uri, collection.user, collection.pass)

      @logger.info("[authorities_harvester] Host : #{collection.host}")
      @logger.info("[authorities_harvester] ID: #{collection.id} Db name: #{collection.name}")
      @logger.info("[authorities_harvester] Connection done to #{collection.host} using #{collection.name}")
			@logger.info("[authorities_harvester] Replication is #{@replication_activated == "0" ? 'disabled' : 'enabled'}")
			@logger.info(last_harvest_msg)

			# Get number of notices to index
      nb_results = 0
      index = 0
      nbError = 0
      query = "SELECT count(*) as nb FROM dw_authoritynotices"
      r = @conn.select_one(query)
      nb_results = r['nb'].to_i
     	
      query_start = Time.now
      query = "SELECT * FROM dw_authoritynotices"
      query = @conn.prepare(query)
      query.execute
      query_time = Time.now - query_start

      @logger.info("[authorities_harvester] Ready to harvest #{nb_results} records (query duration = #{query_time} s)")

			if @replication_activated == '1'
			 solr_replication('disable')
			 mysql_replication('stop')
			end

			clean

			documents = Array.new

			@logger.info("[authorities_harvester] Start harvesting authorities")
      query.fetch do |authority|
        begin
          start_time = Time.now
          raise 'Row nil' if authority.nil?

          ## Indexing data in the search engine
          seq_no = authority['seq_no']
          retenu = authority['retenu']
          rejete = authority['rejete']
          relation = authority['relation']

					retenu = retenu.split(" @;@ ").collect! {|r| r.strip} unless retenu.blank?
					rejete = rejete.split(" @;@ ").collect! {|r| r.strip} unless rejete.blank?
					relation = relation.split(" @;@ ").collect! {|r| r.strip} unless relation.blank?

          # Save in SOLR
					document = {:seq_no => seq_no, :retenu => retenu, :rejete => rejete, :relation => relation}
					documents.push(document)
					
          # Indexing in SOLR every 10K docs 
          if (index > 0 and index % 10000 == 0)
            @index_authorities.add(documents)
            documents.clear
          end
          
          # Commit in SOLR every 10K documents
          if (index > 0 and index % 10000 == 0)
            commit_solr
            @logger.info("10K commited")
          end
          
        rescue Exception => e
          nbError += 1
          @logger.error("[authorities_harvester] #{e.message}")
          @logger.error("[authorities_harvester] Trace : #{e.backtrace.join("\n")}")
        end
        
        index += 1
      end 
      
      query.finish

			# Last solr commit
      @index_authorities.add(documents) unless documents.empty?
    	commit_solr
    	@logger.info("Last commit...")
    	Collection.update(collection.id, { :harvested => DateTime.now })
	
      @conn.disconnect

    rescue => err
      Collection.update_all("harvested = NULL", "id = #{collection.id}")

      @logger.error("[authorities_harvester] Errors : #{$!}")
      @logger.error("[authorities_harvester] Errors : #{err.message}")
      @logger.error("[authorities_harvester] Trace : #{err.backtrace.join("\n")}")
			if @replication_activated
				@logger.error("[authorities_harvester] Switching...")
				switch  
			end
    end
    
		# Harvest ending infos
		Collection.update_all("nb_result = #{index}", "id = #{collection.id}")
		if Parameter.by_name('restart_replication_auto') == '1'
			solr_replication('enable')
			mysql_replication('start') 
		else
			@logger.info("[authorities_harvester] Auto restart replication set to false, replication will not be restarted")
		end
		@logger.info("[authorities_harvester] Finished Indexing : #{index} authorities indexed!!!")
		@logger.info("[authorities_harvester] nb errors: #{nbError}/#{index}")
	
    total_time_end = Time.now 
    @logger.info("[authorities_harvester] Process started at #{total_time_start.strftime("%H:%M")}")
    @logger.info("[authorities_harvester] Process finished at #{total_time_end.strftime("%H:%M")}")
    @logger.info("[authorities_harvester] Process took #{Time.at(total_time_end - total_time_start).utc.strftime('%H heures et %M minutes')}")
  end

	def clean
		@logger.info("[authorities_harvester] Cleaning SOLR & Mysql data")
		@index_authorities.send(Solr::Request::Delete.new(:query => "*:*"))
		@index_authorities.send(Solr::Request::Commit.new)
	end

	def commit_solr
    begin
      @index_authorities.send(Solr::Request::Commit.new)
      @index_authorities = Solr::Connection.new(Parameter.by_name('authorities_solr'), {:timeout => CFG_LF_TIMEOUT_SOLR})
    rescue => err 
      @logger.error("[#{self.class}] error committing to solr : #{err.message}")
      @logger.error("[#{self.class}] error committing to solr : #{err.backtrace.join('\n')}")
    end 
	end

end
