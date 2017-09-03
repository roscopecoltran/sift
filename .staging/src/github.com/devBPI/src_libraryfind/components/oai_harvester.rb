require 'common_harvester'
require 'oai_dc'
require 'time'
class OaiHarvester < CommonHarvester
  
  def initialize
    super
  end
  
  def get_client(hostname, proxy = 0)
    client = OAI::Client.new hostname, :parser => PARSER_TYPE, :timeout => CFG_LF_TIMEOUT
    client.set_logger(@logger)
    if proxy == 1
      yp = YAML::load_file(RAILS_ROOT + "/config/webservice.yml")
      host = yp['PROXY_HTTP_ADR']
      port = yp['PROXY_HTTP_PORT']
			host = host.gsub("http://","") if host.match(/^http:/)
      @logger.info("[oai_harvester] #{hostname} use proxy: #{host} with port #{port} ")
      client.proxy(host, port)
    end
    return client
  end

	def set_options(collection, ref_t, partial_harvesting)
    opts = Hash.new
		opts['set'] = collection.oai_set unless collection.is_parent == 1
		opts['metadata_prefix'] = collection.record_schema
		opts['from'] = ref_t.utc.xmlschema
		unless !partial_harvesting or collection.harvested.nil?
			opts['from'] = collection.harvested.utc.xmlschema unless collection.harvested.blank?
		end
		@logger.info("[oai_harvester] Options: #{opts.inspect}")
		return opts
	end
   
  def harvest(collection_id, partial_harvesting = true)  
    isFound = false
    findError = false    
    collection = Collection.find_by_id(collection_id) 
		ref_t = Time.parse(DateTime.new(1970,01,01).to_s)
    
    old_host = nil
    old_parent = 0
    
    unless old_host.nil? 
      if old_host == collection.host && old_parent == 1
        @logger.info("[oai_harvester] Already harvested... skipping")
        Collection.update(collection.id, { :harvested => DateTime.now })
        next
      elsif old_host != collection.host 
        old_host = ""
      else
        old_host = nil
      end
    end

    nb_total_index = 0
    documents = Array.new
    resumption_token = -1 

    begin 
			@logger.info("[oai_harvester] Id: #{collection.id}")
			@logger.info("[oai_harvester] Name: #{collection.name}")
			@logger.info("[oai_harvester] Host : #{collection.host}")
			@logger.info("[oai_harvester] Collection is parent") if collection.is_parent == true 
			@logger.info("[oai_harvester] Set: #{collection.oai_set}") unless collection.oai_set.empty?
			@logger.info("[oai_harvester] Harvest will be #{partial_harvesting ? 'partial' : 'full'}")
			@logger.info("[oai_harvester] Replication is #{@replication_activated == '0' ? 'disabled' : 'enabled'}")

			if @replication_activated == '1'
				solr_replication('disable')
				mysql_replication('stop')
			end

			if partial_harvesting == false
				@logger.info("[oai_harvester] Cleaning SOLR Harvesting")
				clean_solr_index(collection_id)
				clean_sql_data(collection_id)
			end

			opts = set_options(collection, ref_t, partial_harvesting)

      client = get_client(collection.host, collection.proxy)
      stop = false
      
      until resumption_token.nil? or resumption_token == '' or stop do 
					
				if resumption_token == -1
					begin
						# Setting verb options
		
						records = client.list_records opts
					rescue Exception => e
						@logger.info("[oai_harvester] #{e.message}")
						opts = set_options(collection, ref_t, partial_harvesting) if opts['from'].nil?
						if defined?(e.code) and !e.code.nil?
							if e.code == 'noRecordsMatch'
								@logger.info("[oai_harvester] No data to retrieve")
							elsif (e.message.match(/date/) or e.message.match(/syntax/) or e.message.match(/from/) or e.message.match(/argument/))
								opts['from'] = ref_t.strftime('%Y-%m-%d')
								unless !partial_harvesting or collection.harvested.nil?
									opts['from'] = collection.harvested.strftime('%Y-%m-%d') unless collection.harvested.blank?
								end
								@logger.info("[oai_harvester] Trying other date format: #{opts['from']}")
							end
						else
							@logger.info("[oai_harvester] #{e.message}")
						end

						begin
							records = client.list_records opts
						rescue => e
							if e.message.match(/No data for those parameters/)
								@logger.info("[oai_harvester] No data to retrieve")
								break
							else
								@logger.error("[oai_harvester] #{e.message}")
								raise e
							end
						end
					end

				else
					@logger.info("[oai_harvester] Resumption token #{resumption_token}")
					try_list = true
					has_try = false
					while try_list
						begin
							records = client.list_records :resumption_token => resumption_token
							try_list = false
						rescue => e
							@logger.error("[oai_harvester] Unknown error... Skipping rest of harvest for this site. \n => [code:#{e.class}] \n #{e.message}")
							unless has_try
								if defined?(e.code)
									@logger.warn("[oai_harvester] Error : but retry with code #{e.code}")
								else
									@logger.warn("[oai_harvester] Error : but retry with message #{e.message}")
								end
								has_try = true
							else
								resumption_token = nil
								raise e
							end
						end
					end
				end
          
				@logger.info("[oai_harvester] Response is nil") if records.nil?
          
				resumption_token = resumption_token == '' ? nil : records.resumption_token
          
				x = 0
				oaidc = OaiDc.new
				records.each do |record|
					set_spec = record.header.set_spec.to_s.gsub(/<\/?[^>]*>/, "")
					oaidc.parse_metadata(record)

					prim_title = oaidc.title.nil? ? 'untitled' : checknil(oaidc.title[0])
					oai_identifier = record.header.identifier
					prim_description = oaidc.description.nil? ? '' : checknil(oaidc.description[0])

					control = Control.find(:first, :conditions => ["oai_identifier = ? and collection_id = ?", oai_identifier, collection.id])
					isFound = true
					if control.nil?
						control = Control.new
						isFound = false
					end

					url = ''
          unless oaidc.identifier.nil? or oaidc.identifier.empty?
						oaidc.identifier.each do |idm|
							url = idm if idm.starts_with?("http://")
						end
					end
            
					control.oai_identifier = oai_identifier
					control.title = prim_title
					control.collection_id = collection.id
					control.description = prim_description
					control.url = url
					control.collection_name = collection.name
					control.save!
            
					raise "Error: control id is nil" if control.id.nil?
            
					last_id = control.id
					dctitle, dccreator, dcsubject, dcdescription, dcpublisher, dccontributor, dcdate, dctype, dcformat, dcidentifier, dcsource,
					dcrelation, dccoverage, dcrights, dcthumbnail, keyword, dclanguage = [''] * 17

					dctitle = oaidc.title.join("; ").gsub('; ;',';') unless oaidc.title.nil?

					unless oaidc.creator.nil?
						dccreator = oaidc.creator.join("; ").gsub('; ;',';') 
						oaidc.creator.each do |creator|
							unless creator.nil? 
								unless creator.index(',').nil?
									creator_parts = creator.split(',')
									dccreator << "#{creator_parts[1]} #{creator_parts[0]};" if creator_parts.length >= 2
								end
							end
						end
					end

					dcsubject = oaidc.subject.uniq.join("; ").gsub('; ;',';') unless oaidc.subject.nil?
					dcdescription = dcdescription = oaidc.description.join("; ").gsub('; ;',';') unless oaidc.description.nil?
					dcpublisher = oaidc.publisher.uniq.join("; ").gsub('; ;',';') unless oaidc.publisher.nil?
					dccontributor = oaidc.contributor.uniq.join("; ").gsub('; ;',';') unless oaidc.contributor.nil?
					dcdate = oaidc.date.join("; ").gsub('; ;',';') unless oaidc.date.nil?
					dclanguage = oaidc.language.uniq.join("; ").gsub('; ;',';') unless oaidc.language.nil?
					dctype = oaidc.type.uniq.join("; ").gsub('; ;',';') unless oaidc.type.nil?
					dctype = DocumentType.save_document_type(dctype, collection.id)
					dcformat = oaidc.format.uniq.join("; ").gsub('; ;',';') unless oaidc.format.nil?
					dcidentifier = oaidc.identifier.join("; ").gsub('; ;',';') unless oaidc.identifier.nil?
					dcsource = oaidc.source.join("; ").gsub('; ;',';') unless oaidc.source.nil?
					dcrelation = oaidc.relation.uniq.join("; ").gsub('; ;',';') unless oaidc.relation.nil?
					dccoverage = oaidc.coverage.uniq.join("; ").gsub('; ;',';') unless oaidc.coverage.nil?
					dcrights = oaidc.rights.uniq.join("; ").gsub('; ;',';') unless oaidc.rights.nil?

					keyword = [dctitle, dccreator, dcsubject, dcdescription, dcpublisher, dccontributor, dccoverage, dcrelation, dctype].join(' ')	

					# If thumbnail is blank and the item is set an an image, then we 
					# assume that its a CONTENTdm resource (for now) and build a link to the
					# CDM image.
					dcthumbnail = oaidc.thumbnail.join("") unless oaidc.thumbnail.nil?
					if collection.mat_type.downcase == 'image' and dcthumbnail == ''
						thumbstem = url.split('u?')[0]
						thumbargs = url.split('u?/')[1]
						unless thumbargs.nil? or thumbargs.empty?
							thumbarg_parts = thumbargs.split(',')
							dcthumbnail = thumbstem + 'cgi-bin/thumbnail.exe?CISOROOT=/' + thumbarg_parts[0] +'&CISOPTR=' + thumbarg_parts[1]
						end
					end
					dcthumbnail = dcrelation if dcrelation.match(/^http:\/\/.*[jpg|png|bmp]$/) and !dcrelation.nil?
            
					metadata = Metadata.find(:first, :conditions => ["controls_id = ?", last_id])
					isFound = true
					if metadata.nil?
						metadata = Metadata.new
						isFound = false
					end

					metadata.controls_id = last_id
					metadata.collection_id = collection.id
					metadata.dc_title = dctitle
					metadata.dc_creator = dccreator
					metadata.dc_subject = dcsubject
					metadata.dc_description = dcdescription
					metadata.dc_publisher = dcpublisher
					metadata.dc_contributor = dccontributor
					metadata.dc_date = dcdate
					metadata.dc_type = dctype
					metadata.dc_format = dcformat
					metadata.dc_identifier = oai_identifier
					metadata.dc_source = dcsource
					metadata.dc_relation = dcrelation
					metadata.dc_coverage = dccoverage
					metadata.dc_rights = dcrights
					metadata.dc_language = dclanguage
					metadata.osu_thumbnail = dcthumbnail
					metadata.save!

					main_id = metadata.id
            
					id = [oai_identifier, collection.id].join(';')
            
					documents.push({  :id => id, 
														:collection_id => collection.id, 
														:collection_name => collection.name, 
														:controls_id => last_id, 
														:title => [dctitle, dcrelation].join(' '),
														:subject => dcsubject, 
														:creator => [dccreator, dccontributor].join(' '),
														:keyword => keyword, 
														:title_sort=> UtilFormat.normalize(dctitle),
														:autocomplete => keyword,
														:document_type => dctype, 
														:harvesting_date => Time.new,
														:dispo_sur_poste => collection.availability,
														:dispo_bibliotheque => collection.availability,
														:dispo_access_libre => collection.availability,
														:dispo_avec_reservation => collection.availability,
														:dispo_avec_access_autorise => collection.availability,
														:dispo_broadcast_group => FREE_ACCESS_GROUPS.split(","),
														:lang_exact => dclanguage,
														:boost => UtilFormat.calculateDateBoost(dcdate),
														:date_document => UtilFormat.normalizeSolrDate(oaidc.date)})
						
					update_notice(id, dctitle, dccreator, dctype, nil, Time.new)

					if nb_total_index > 0 and nb_total_index % 1000 == 0
						@index.add(documents)
						documents.clear
					end
						
					if nb_total_index > 0 and nb_total_index % 10000 == 0
						@logger.info("[oai_harvester] 10K documents committed to solr")
						commit
					end
            
					x += 1
					nb_total_index += 1
				end 
			end # until resumption_token.nil? or stop
              
		rescue => err
			if err.message.match(/No data for those parameters/)
				@logger.info("[oai_harvester] No data (err: #{err.message})")
			else
				@logger.error("[oai_harvester] #{err.message}.")
				@logger.error("[oai_harvester] Class : #{err.class}]")
				@logger.error("[oai_harvester] Trace: \n#{err.backtrace}")
				findError = true   
			end
		end
            
		unless documents.empty? 
			@index.add(documents)
			documents.clear
		end
            
		@logger.info("[oai_harvester] #{collection.alt_name}: #{nb_total_index} documents harvested!")
		if !findError and nb_total_index > 0
			Collection.update(collection.id, { :harvested => DateTime.now, :nb_result => nb_total_index })
		else
			Collection.update(collection.id, { :harvested => nil, :nb_result => nb_total_index })
		end
            
		if collection.is_parent == 1
			old_host = collection.host
			old_parent = 1 
		elsif old_host == collection.host && old_parent == 1
			old_host = collection.host
			old_parent = 1
		else
			old_host = collection.host
			old_parent = 0
		end 
							
		@logger.info("[oai_harvester] Last commit...")
		commit

		if @replication_activated == '1' and @replication_auto  == '1'
			solr_replication('enable')
			mysql_replication('start') 
		end

	end

end
