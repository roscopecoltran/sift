require 'common_harvester'

class GedRecord
	# Attr description
	# nuid: dc_identifier (document id)
	# dat1: document_date (date of the document)
	# dat2: dc_date
	# desg: part of dc_subject
	# dess: part of dc_subject
	# desp: part of dc_subject
	# sour: dc_publisher (author)
	# aut: part of dc_subject (author)
	# gdes: part of dc_subject 
	# gmon: part of dc_subject
	# term: part of dc_subject
	# tidx: part of dc_subject
	# cont: dc_description (description) 
	attr_accessor :nuid, :dat1, :dat2, :desg, :dess, :desp, :sour, :tiun, :aut, :gdes, :gmon, :term, :tidx, :cont
end

class GedHarvester < CommonHarvester
  
  def initialize
    super
  end

	def sanitize_sql(string)
		string = "" if string.nil?
		ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['?', string])
	end

  
  def harvest(collection_id, diff = false)
    collection = Collection.find_by_id(collection_id)
    begin  

			last_harvest = collection.harvested
			@logger.info("[ged_harvester] Database: #{@db[:database]} (on #{@db[:host]})")
			@logger.info("[ged_harvester] The last harvest was the #{last_harvest.strftime("%d/%m/%Y at %H:%M")}") unless last_harvest.nil?
		  @logger.info("[ged_harvester] Replication is #{@replication_activated == "0" ? 'disabled' : 'enabled'}")
      @logger.info("[ged_harvester] Harvesting #{collection.host}")

      start = Time.now

			if @replication_activated == "1"
				solr_replication('disable')
				mysql_replication('stop')
			end

			@logger.info("[ged_harvester] Cleaning SOLR & Mysql data")
			clean_solr_index(collection.id)
      clean_sql_data(collection.id)
      
      @logger.info("[ged_harvester] Start harvesting")
      
			ids = Array.new
			metadata_inserts = Array.new
			control_inserts = Array.new
      documents = Array.new
      n = 0

			# Treating file
      conv_file = "#{collection.host}_conv"
      system("rm #{conv_file}")
      system("uconv -f iso-8859-1 -c -i -t utf-8 #{collection.host} > #{conv_file}")

			File.open(conv_file, "r:iso-8859-1:utf-8").each_with_index do |line, idx| 
				begin 
					datas = line.split("\t") 
					next if datas[0] == 'NUID'
					if !ids.include? datas[0] and datas.length > 4 # skip if wrong data or duplicate
						ids << datas[0]
					
						# Create ged record using line file data and array listing all attributes ordered
						attributes = %w{nuid dat1 dat2 desg dess desp sour tiun aut gdes gmon term tidx cont} 
						ged = GedRecord.new
						datas.each_with_index {|data, i| ged.instance_variable_set("@#{attributes[i]}", data.chomp)}
						
						# Building SQL & SOLR data
						dc_identifier = ged.nuid
						document_date = ged.dat1.nil? || ged.dat1 == '0' ? "" : Date.parse(ged.dat1).strftime("%Y-%m-%d") 
						dc_date = ged.dat2.nil? || ged.dat2 == '0' ? "" : Date.parse(ged.dat2).strftime("%Y-%m-%d") 
						dc_publisher = ged.sour
						dc_title = ged.tiun.gsub('\n', ';') unless ged.tiun.nil?
						dc_description = ged.cont
						dc_source = collection.alt_name

						dc_subject = [ged.desg, ged.dess, ged.desp, ged.aut, ged.gmon, ged.tidx, ged.term, ged.gdes].join(" ").gsub('\n', ';')
						dc_type = DocumentType.save_document_type(collection.mat_type, collection.id)
						keyword = [dc_title, dc_subject, dc_description, dc_publisher, dc_type].join(" ")

						c_title = "#{dc_publisher} : #{dc_title}"

						# Create control statement
						control_statement = [dc_identifier, c_title, collection.id, dc_description, collection.url, collection.name].collect! { |control| sanitize_sql(control)}.join(",")
						control_inserts.push("(#{control_statement})")

						# Create metadata statement
						metadata_statement = [collection.id, dc_title, dc_subject, dc_description, dc_publisher, dc_date, dc_type, dc_identifier, dc_source].collect! {|metadata| sanitize_sql(metadata)}.join(", ")
						metadata_inserts.push("(#{metadata_statement})")
				
						solr_id = "#{dc_identifier};#{collection.id}"
						harvesting_date = document_date.blank? ? Time.now.strftime('%Y-%m-%dT%H:%M:%SZ') : "#{document_date}T23:59:59Z"
						date_end_new = DocumentType.getDateEndNew(dc_type, document_date, collection.id) unless document_date.nil?

						# Building solr statement
						document = 	{	:id => solr_id, :collection_id => collection.id,
													:collection_name => collection.name,  
													:title => dc_title ,:subject => dc_subject, :creator => "", 
													:keyword => keyword, :document_type => dc_type, 
													:harvesting_date => harvesting_date, :title_sort => c_title, 
													:dispo_avec_access_autorise => collection.availability,
													:dispo_broadcast_group => FREE_ACCESS_GROUPS.split(","),
													:boost => UtilFormat.calculateDateBoost(dc_date),
													:date_document => UtilFormat.normalizeSolrDate(dc_date) 
												}
						document[:date_end_new] = date_end_new unless date_end_new.nil?
						documents.push(document)

						update_notice(solr_id, dc_publisher, "", dc_type, "", Time.new)

						# Indexing in Solr and commit to mysql every 1K docs
							if (idx > 0 and idx % 1000 == 0)
							last_id = insert(metadata_inserts, control_inserts, collection.id)
							update_solr_documents(documents, last_id)
							@index.add(documents)
							documents.clear
						end

						# Commit in SOLR every 10K documents
						if (idx > 0 and idx % 10000 == 0)
							@logger.info("[ged_harvester] 10K records ==> Committing in Solr...")
							commit_start_time = Time.now
							commit
							commit_duration = (Time.now - commit_start_time).round(2)
							@logger.info("[ged_harvester] Commit took #{commit_duration} seconds")
						end

						 n += 1
					end

				rescue Exception => e 
					@logger.error("[ged_harvester] error line #{idx} => #{e.message}")
					@logger.error("[ged_harvester] stack: => #{e.backtrace.join("\n")}")
					@logger.error("[ged_harvester] ged record: #{ged.inspect}")
					next
				end
			end 

			# Last Mysql insert & Solr commit
			unless documents.empty? or metadata_inserts.empty? or control_inserts.empty?
				@index.add(documents) 
				last_id = insert(metadata_inserts, control_inserts, collection.id)
				update_solr_documents(documents, last_id)
				@logger.info("[ged_harvester] Last commit!")
				commit_start_time = Time.now
				commit
				commit_duration = (Time.now - commit_start_time).round(2)
				@logger.info("[ged_harvester] Commit took #{commit_duration} secs")
			end

			create_relations(collection.id)

			@logger.info("[ged_harvester] Finished indexing : #{n} documents indexed !!!")
      
    rescue => err 
      @logger.error("[ged_harvester] #{err.message.to_s}")
    end
    
    Collection.update(collection.id, { :harvested => DateTime.now, :nb_result => n, :full_harvest => true})
		time = (Time.now - start).to_s
    @logger.info("[ged_harvester] ###### Temps total: #{time} seconds. #######")
		if @replication_activated == '1'
			if Parameter.by_name('restart_replication_auto') == '1'
				solr_replication('enable')
				mysql_replication('start')
			else
				@logger.info("[portfolio_harvester] Auto restart replication set to false, replication will not be restarted")
			end
		end

  end

  # Insert data arrays into Mysql (tables metadatas, controls)
  def insert(metadata_inserts, control_inserts, collection)
    transaction_start = Time.now
		last_id = ""
    ActiveRecord::Base.transaction do
      begin
        unless metadata_inserts.size == 0
          ActiveRecord::Base.connection.execute("INSERT INTO controls(oai_identifier, title, collection_id, description, url, collection_name) 
                                               	 VALUES #{control_inserts.join(", ")}")
					last_id = ActiveRecord::Base.connection.select_all("SELECT LAST_INSERT_ID();").first["LAST_INSERT_ID()"].to_i
          ActiveRecord::Base.connection.execute("INSERT INTO metadatas(collection_id, dc_title, dc_subject, dc_description, dc_publisher, 
																								 dc_date, dc_type, dc_identifier, dc_source) 
                                              	 VALUES #{metadata_inserts.join(", ")}")
          control_inserts.clear
          metadata_inserts.clear
        end
      rescue ActiveRecord::Rollback => e
        Collection.update_all("harvested = NULL", "id = #{collection}")
        @logger.error("[ged_harvester] Insert transaction has been rolled back => #{e.message}")
      rescue Exception => e
        Collection.update_all("harvested = NULL", "id = #{collection}")
        @logger.error("[ged_harvester] Error committing documents in MySql => #{e.message}")
        raise e
      end
    end
		duration = (Time.now - transaction_start).round(2)
    @logger.info("[ged_harvester] 1K Mysql insert (#{duration} secs)")
		return last_id
  end

  # Update metadatas to set controls ids
  def create_relations(collection_id)
    ActiveRecord::Base.transaction do
      begin
        update_start = Time.now
        update_sql = "	UPDATE metadatas M SET M.controls_id = 
												(SELECT C.id FROM controls C 
												WHERE C.collection_id = #{collection_id} AND M.collection_id = #{collection_id} 
												AND C.oai_identifier = M.dc_identifier)
                      	WHERE M.collection_id=#{collection_id}"
        ActiveRecord::Base.connection.execute(update_sql)
				update_duration = (Time.now - update_start).round(2)
        @logger.info("[ged_harvester] Metadatas foreign keys updated in #{update_duration} secs")
      rescue ActiveRecord::Rollback => e
        @logger.error("[ged_harvester] Metadatas foreign keys update been rolled back => #{e.message}")
      rescue Exception => e
				@logger.error("[ged_harvester] Error updating metadatas foreign keys => #{e.message}")
        raise e
      end
    end
  end

	# Update controls_id in solr documents after controls insert
	def update_solr_documents(documents, last_id)
		documents.each_with_index do |doc, k|
			doc[:controls_id] = last_id + k
		end
	end
      
end
