require 'common_harvester'
require 'net/http'
require 'uri'
require 'dbi'
require 'xml'
require 'nokogiri'
require ENV['LIBRARYFIND_HOME'] + 'app/models/themes_reference'
require ENV['LIBRARYFIND_HOME'] + 'app/models/theme'
require ENV['LIBRARYFIND_HOME'] + 'components/portfolio/portfolio_theme'

class PortfolioHarvester < CommonHarvester
  
  yp = YAML::load_file(RAILS_ROOT + "/config/ranking.yml")
  BPI_BOOST = yp['CATALOGUE_BPI_BOOST']
  REVUE_BOOST = yp['PORTFOLIO_REVUE_BOOST']

  def initialize
    super
  end
  
  def normalizePortfolio(word)
    return "" if word == nil
    word.gsub!("@;@", "|LF_DEL|")
    word.gsub!(";", ",")
    word.gsub!(", , ", ", ")
    word.gsub!("/ , ", ", ")
    word.gsub!("|LF_DEL|", ";")
    word.gsub!(", ;", ",")
    word.chomp!(",")
    word.chomp!("/;")
    word.chomp!(";")
    word.chomp!("/")
    return word
  end
  
  def normalizeTitle(word)
    word = normalizePortfolio(word)
    word.gsub!(" : ; ", " : ")
    word.gsub!(" : / ", " : ")
    word.gsub!(" / : ", " : ")
    word.gsub!(" / ; ", "; ")
    word.gsub!(" = ; ", "; ")
    word.chomp!(",")
    word.chomp!("/;")
    word.chomp!(";")
    word.chomp!("/")
    return word
  end
  
  def sanitize_sql(string)
    string = "" if string.nil?
    ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['?', string])
  end
  
  def harvest(collection_id, partial_harvesting)

    total_time_start = Time.now
    @logger.info("[portfolio_harvester] DATABASE INFO: #{@db["database"]}")
    begin
			# Initialize portfolio informations and DBI connection
      collection = Collection.find_by_id(collection_id)
      ids = Array.new
      last_harvest = collection.harvested
			last_harvest_msg = "[portfolio_harvester] The last harvest failed" 
			last_harvest_msg = "[portfolio_harvester] The last harvest was the #{last_harvest.strftime("%d/%m/%Y at %H:%M")}" unless last_harvest.nil?
      uri = "DBI:Pg:database=#{collection.name};host=#{collection.host}"
      @conn = DBI.connect(uri, collection.user, collection.pass)
      themePortfolio = PortfolioTheme.new(@conn, @logger)

      @logger.info("[portfolio_harvester] Host : #{collection.host}")
      @logger.info("[portfolio_harvester] ID: #{collection.id} Db name: #{collection.name}")
      @logger.info("[portfolio_harvester] Connection done to #{collection.host} using #{collection.name}")
      @logger.info("[portfolio_harvester] Harvest will be #{partial_harvesting ? 'partial' : 'full'}")
			@logger.info("[portfolio_harvester] Replication is #{@replication_activated == "0" ? 'disabled' : 'enabled'}")
			@logger.info(last_harvest_msg)

			# If not full harvest, get ids of notices updated after last harvest.
			# If more than 1k ids, launch full harvest instead
			# If no ids, skipping harvesting process
      if partial_harvesting 
				last_harvest = Date.today - 1.week if last_harvest.nil?
				query = "SELECT dc_identifier FROM dc_notices_flags WHERE time > '#{last_harvest.strftime("%Y-%m-%d")}'"
				#query = "select dc_identifier from dc_notices where bpi_publishercountry <> '' and bpi_dm_launch <> ''"
				#query = "select dc_identifier from dc_notices where dc_type = 'CARTE'"
				#query = "select dc_identifier from dc_notices where bpi_notes_ex <> ''"
				#query = "SELECT dc_identifier FROM dc_notices where dc_type in ('EMUSICAL', 'CDLIV', 'EPARLE')"
				#query = "select dc_identifier from dc_notices where dc_identifier in (64526)"
				#query = "select dc_identifier from dc_notices where bpi_indice = '81.041'"
				#query = "select dc_identifier from dc_notices where bpi_dm_launch <> ''"
				#query = "select dc_identifier from dc_notices where bpi_dm_access <> ''"
        query = @conn.prepare(query)
        query.execute
        query.fetch do |notice_updated|
          ids.push(notice_updated['dc_identifier'])
        end
        query.finish
        if ids.size > 200000
          @logger.info("[portfolio_harvester] more than 100000 modified records... Launching full harvest")
          ids.clear
          partial_harvesting = false
        elsif ids.size == 0
          @logger.info("[portfolio_harvester] No changed records... Skipping")
					Collection.update(collection.id, { :harvested => DateTime.now })
          @conn.disconnect
          return
				end
      end

			# Get number of notices to index
      nb_results = 0
      index = 0
      nbError = 0
      query = "SELECT count(*) as nb FROM dc_notices"
      query += " WHERE dc_identifier in (#{ids.join(",")})" unless ids.empty?
      r = @conn.select_one(query)
      nb_results = r['nb'].to_i
     	
     	# Get notices to index (all notices or updated ones) 
      query_start = Time.now
      query = "SELECT * FROM dc_notices"
      query += " WHERE dc_identifier IN (#{ids.join(",")})" unless ids.empty?
      query = @conn.prepare(query)
      query.execute
      query_end = Time.now
      query_time = query_end - query_start

      @logger.info("[portfolio_harvester] Ready to harvest #{nb_results} records (query duration = #{query_time} s)")

			if @replication_activated == '1'
				solr_replication('disable')
				mysql_replication('stop')
			end

			# If full harvest, clear all solr & mysql data (controls, metadatas, volumes and portfolio_datas) 
			# If partial, cleaning only concerned notices 
      @logger.info("[portfolio_harvester] Cleaning SOLR & Mysql data")
      clean_solr_index(collection_id, ids)
      clean_sql_data(collection_id, ids)
      cleanquery = "delete from portfolio_datas" 
      cleanquery += " WHERE dc_identifier in (#{ids.join(" ,")})" unless ids.empty?
      ActiveRecord::Base.connection.execute(cleanquery)

			# Initialize sql arrays and variables
      metadata_inserts = Array.new
      control_inserts = Array.new
      portfolio_data_inserts = Array.new
      volume_inserts = Array.new
      volumes = Array.new
      documents = Array.new

			# Begin harvesting notice by notice (ends at l.475)
			@logger.info("[portfolio_harvester] Start harvesting notices")
      query.fetch do |notice|
        begin
          start_time = Time.now
          raise 'Row nil' if notice.nil?

          ## Indexing data in the search engine
          identifier = notice['dc_identifier']
          title = normalizeTitle(notice['dc_title'])
          creator = normalizePortfolio(notice['dc_creator'])
          subject = normalizePortfolio(notice['dc_subject'])
          description = normalizePortfolio(notice['dc_description'])
          publisher = normalizePortfolio(notice['dc_publisher'])
          language = normalizePortfolio(notice['dc_language_long'])
          issn = normalizePortfolio(notice['bpi_issn'])
          isbn = normalizePortfolio(notice['bpi_isbn'])
          contributor = normalizePortfolio(notice['dc_contributor'])
          relation = normalizePortfolio(notice['dc_relation'])
          last_issue = notice['bpi_dernier_no']
          issues = notice['bpi_collection']
          binding = notice['bpi_reliure']
          dcdate = notice['dc_date_long']
          custom_document_type = notice['dc_type']
          issue_title = notice['dc_title_revue']
          conservation = notice['bpi_conservation'] 
          # POUR 10.1.2.8 
					#label_indice = normalizePortfolio(themePortfolio.getCDU(notice['bpi_indice'].gsub(';', '@;@')))
					# POUR 10.1.2.100
          label_indice = normalizePortfolio(themePortfolio.getCDU(notice['bpi_indice']))
					country = normalizePortfolio(notice['bpi_publishercountry'])
					abstract = normalizePortfolio(notice['bpi_abstract'])
					indice = normalizePortfolio(notice['bpi_indice'])

          # Format duration if any
					dcformat = normalizePortfolio(notice['dc_format'])
					duration_regexp = /[0-9]{2}[0-5][0-9]([0-5][0-9])?/
					match = duration_regexp.match(dcformat)
					if match
						duration = match[0]
						hours = "#{duration[0..1]} heure(s)" unless duration[0..1] == '00'  
						minutes = "#{duration[2..3]} minute(s)" unless duration[2..3] == '00' or duration[2..3].empty?
						seconds = "#{duration[4..5]} seconde(s)" unless duration[4..5] == '00' or duration[4..5].empty?
						duration = [hours, minutes, seconds].join(" ")
						dcformat = dcformat.gsub(duration_regexp, duration)
					end

					# Treatments for musical documents
					commercial_number = ''
					if ['EMUSICAL', 'CDLIV', 'EPARLE', 'LIVREAUDIO'].include? notice['dc_type']
						commercial_number = notice['bpi_numeroscommerciaux']
						unless notice['dc_type'] == 'LIVREAUDIO'
						  musical_kind = notice['bpi_genre_mus']
						  musical_kind.slice! "Musiques > " unless musical_kind.empty?
						  dcformat.slice! " ; En ligne" unless dcformat.empty?
						end
					end

					# Boost if notice is type of revue
				  if notice['dc_type'] == "REVUE" or notice['dc_type'] == "REVUELEC"
            portfolio_revue = REVUE_BOOST
          else
            portfolio_revue = 0
          end
          type = DocumentType.save_document_type(notice['dc_type'], collection.id)
          
          if !contributor.blank?
            contributor += ";#{normalizePortfolio(notice['bpi_creator2'])}"
          else
            contributor = "#{normalizePortfolio(notice['bpi_creator2'])}"
          end

	  			# Data for SIG
	  			coverage_spatial = normalizePortfolio(notice['dc_coverage_spatial']).gsub(" @;@ ", ";") unless notice['dc_coverage_spatial'].blank?
          coverage_temporal = normalizePortfolio(notice['dc_coverage_temporal']).gsub(" @;@ ", ";") unless notice['dc_coverage_temporal'].blank?
	  			coverage_spatial_index = coverage_spatial.nil? ? coverage_spatial :  coverage_spatial.split(";")
	  			coverage = [coverage_spatial, coverage_temporal].reject {|c| c.blank?}.compact.join(";")
	  
					# Concatenate rights and copy if copy exists
					dcrights = notice['dc_rights']
					dcrights = "#{notice['bpi_copy']}.\n #{dcrights}" unless notice['bpi_copy'].blank?

          # Calculate and store the date when the notice won't be considered as new
          document_date = notice['bpi_nouveaute'].blank? ? nil : notice['bpi_nouveaute']
          date_end_new = nil
          if !notice['bpi_dispo'].blank? and notice['bpi_dispo'].starts_with?("D")
            date_end_new = DocumentType.getDateEndNew(type, document_date, collection['id'])
          end
          
          # Create array of notice cotes with leading and trailing whitespaces removed for each cote
          unless notice['bpi_cote'].blank?
            cote = notice['bpi_cote'].split(" @;@ ").collect! {|c| c.strip}
          end
          
          # Retrieve infos for notice multimedia objects (one dm_launch = one object)
          bdm_info = Array.new
          vol_title = notice['bpi_dm_title'].split(" @;@ ") unless notice['bpi_dm_title'].blank?
					dm_launch = notice['bpi_dm_launch']
					barcode_field = ""
          unless dm_launch.blank?
            dm_launch.split(" @;@ ").each_with_index do |dm, i|
							# Get bdm, iddoc, idomm and idweb from url pattern
              bdm, iddoc, idomm = "", "", ""
              match = dm.match(/http:\/\/.*\/([a-z]+)\/LaunchOMM\.aspx\?IdDoc=(\d+)&IdOmm=(\d+)/)
              unless match.nil?
                bdm = match[1] unless match[1].nil? 
                iddoc = match[2] unless match[2].nil?
                idomm = match[3] unless match[3].nil?
              end
              idweb, match = nil
              if dm.match(/IdWeb/)
                match = dm.match(/IdWeb=(\d+)/)
                idweb = match[1]
              end

              doc_title = ""
              doc_title = vol_title[i] unless vol_title.nil? or vol_title[i].nil?

							barcode = notice['bpi_dm_barcode'].blank? ? "" : notice['bpi_dm_barcode'].split(" @;@ ")
              barcode = barcode[i] unless barcode[i].nil? or barcode.kind_of?(String) or barcode.nil?
              barcode_field = notice['bpi_dm_barcode'].split("@;@") unless notice['bpi_dm_barcode'].blank?


              bdm_tmp = "bdm=#{bdm}|iddoc=#{iddoc}|idomm=#{idomm}|doc_title=#{doc_title}|barcode=#{barcode}"
              bdm_tmp = "#{bdm_tmp}|idweb=#{idweb}" unless idweb.nil?

              bdm_info.push(bdm_tmp)
              bdm_tmp = "" 
            end 
          end

					# Copying bdm info if type of doc is film and nb of launch not equal to nb of volumes
					if notice['dc_type'] == 'FILM' and notice['bpi_dispo_ex'].split('@;@').size != notice['bpi_dm_launch']
						nb = notice['bpi_dispo_ex'].split('@;@').size - 1
						nb.times { bdm_info.push(bdm_info.first) }
					end

					# Calculate theme depending if notice comes from cdu or bdm 
					theme = ''
					if dm_launch.blank? 
						theme = notice['bpi_theme_lib']
          	theme = themePortfolio.translateCduThemes(notice['bpi_indice'].gsub(';', '@;@')) if !notice['bpi_indice'].blank? and theme.blank?
					else
						bdm = bdm_info[0].match(/bdm=([a-z]+)|/i)[1]
						theme = themePortfolio.translateBdmThemes(notice['bpi_theme'], notice['bpi_theme_lib'], bdm) unless notice['bpi_theme'].blank? or notice['bpi_theme_lib'].blank? 
					end 
					musical_kind_keyword = musical_kind.nil? ? "" : musical_kind
					barcode_field_keyword = barcode_field.kind_of?(Array) ? barcode_field.join(" ") : barcode_field
          keyword = normalizePortfolio(title + " " + creator + " " + contributor + " " + subject + " " + description + " " + publisher + " " + theme + " " + type + " " + relation + " " + musical_kind_keyword + " " + barcode_field_keyword + " " + abstract) 

          # Create control statement
          control_statement = "(#{sanitize_sql(identifier)}, #{sanitize_sql(title)}, #{sanitize_sql(collection_id)}, #{sanitize_sql(description)}, #{sanitize_sql(collection.name)})"
          control_inserts.push(control_statement)
          
          # Create metadata statement
          metadata_statement = "(	#{collection.id}, #{sanitize_sql(title)}, #{sanitize_sql(creator)},
					                      	#{sanitize_sql(subject)}, #{sanitize_sql(description)}, #{sanitize_sql(publisher)},
				                      		#{sanitize_sql(contributor)}, #{sanitize_sql(dcdate)}, #{sanitize_sql(type)},
                      						#{sanitize_sql(dcformat)}, #{sanitize_sql(identifier)}, #{sanitize_sql(relation)},
                      						#{sanitize_sql(coverage)}, #{sanitize_sql(dcrights)}, #{sanitize_sql(language)}, #{sanitize_sql(coverage_spatial)})"
          metadata_inserts.push(metadata_statement)

          # Create portfolio_data statement
          if !notice['bpi_dispo'].blank? and notice['bpi_dispo'].starts_with?("D")
            portfolio_data_available = 1
          else
            portfolio_data_available = 0
          end

					broadcast_groups = notice['bpi_gr_diff'].gsub(/ @;@ /,";") unless notice['bpi_gr_diff'].blank?

          portfolio_data_statement = "(	#{sanitize_sql(identifier)}, #{sanitize_sql(notice['bpi_audience'])}, #{sanitize_sql(notice['bpi_genre'])},
                                        #{sanitize_sql(last_issue)}, #{sanitize_sql(issn)}, #{sanitize_sql(isbn)},
                                        #{sanitize_sql(theme)}, #{portfolio_data_available}, #{sanitize_sql(indice)}, #{sanitize_sql(label_indice)},
                                        #{sanitize_sql(broadcast_groups)}, #{sanitize_sql(issues)}, #{sanitize_sql(binding)},
                                        #{sanitize_sql(issue_title)}, #{sanitize_sql(conservation)}, #{sanitize_sql(commercial_number)}, 
																				#{sanitize_sql(musical_kind)}, #{sanitize_sql(country)}, #{sanitize_sql(abstract)})"
          portfolio_data_inserts.push(portfolio_data_statement)
          
          # Create volume statements
					note = notice['bpi_notes_ex'].split(" @;@ ") unless notice['bpi_notes_ex'].blank? or notice['dc_type'] == 'CARTE'
          call_num = notice['bpi_cote'].split(" @;@ ") unless notice['bpi_cote'].blank? 
          location = notice['bpi_loca'].split(" @;@ ") unless notice['bpi_loca'].blank? 
          label = notice['bpi_dm_lien_lib'].split(" @;@ ") unless notice['bpi_dm_lien_lib'].blank?
          launch_url = notice['bpi_dm_launch'].split(" @;@ ") unless notice['bpi_dm_launch'].blank?
          support = notice['dc_format_court'].split(" @;@ ") unless notice['dc_format_court'].blank?
          resource_link = notice['bpi_dm_lien_url'].split(" @;@ ") unless notice['bpi_dm_lien_url'].blank?
					launchable = notice['bpi_dm_type'].split(" @;@ ") unless notice['bpi_dm_type'].blank?
					external_access = notice['bpi_dm_access'].split(" @;@ ") unless notice['bpi_dm_access'].blank?

					volume_statement = Hash.new
					volume_statement[:identifier] = identifier
					volume_statement[:id] = collection.id				
          volume_statement[:barcode], volume_statement[:doc_id], volume_statement[:object_id], volume_statement[:source] = "", "", "", ""

          volumes_element = Hash.new
          volumes_element[:format] = dcformat

					idx = 0
          if !notice['bpi_dispo_ex'].blank? and (!dm_launch.match(/IdOmm.*@;@/) or !dm_launch.match(/.*@;@.*IdOmm/)) 
            notice['bpi_dispo_ex'].split(" @;@ ").each do |volume|
							volume_statement[:note] = note[idx].to_s.strip unless note.nil? or note[idx].nil?
              volume_statement[:call_num] = call_num[idx].to_s.strip unless call_num.nil? or call_num[idx].nil? 
              volume_statement[:record_location] = location[idx].to_s.strip unless location.nil? or location[idx].nil?
							volume_statement[:dispo] = volume.strip

              if vol_title.blank? or vol_title[idx].blank?
                if label.blank? or label[idx].blank?
                  volume_statement[:label] = title
                else
                  volume_statement[:label] = label[idx] unless label[idx].blank?
                end
              elsif vol_title.kind_of?(String)
                volume_statement[:label] = title
              else
                volume_statement[:label] = vol_title[idx]
              end
             
              volume_statement[:link] = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_statement[:launch_url] = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_statement[:support] = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_statement[:number] = idx + 1
          		volume_statement[:barcode], volume_statement[:doc_id], volume_statement[:object_id], volume_statement[:source] = "", "", "", ""
              unless bdm_info.nil? or bdm_info[idx].nil?
                volume_statement[:barcode] = bdm_info[idx].match(/barcode=(\d+)/)[1] if bdm_info[idx].match(/barcode=(\d+)/)
                volume_statement[:doc_id] = bdm_info[idx].match(/iddoc=(\d+)/)[1] if bdm_info[idx].match(/iddoc=(\d+)/)
                volume_statement[:object_id] = bdm_info[idx].match(/idomm=(\d+)/)[1] if bdm_info[idx].match(/idomm=(\d+)/) 
                volume_statement[:source] = bdm_info[idx].match(/bdm=([a-z]+)|/i)[1] if bdm_info[idx].match(/bdm=([a-z]+)|/i)
              end
							unless launchable.nil? or launchable[idx].nil?
								volume_statement[:launchable] = launchable[idx] == '0' ? false : true
							end
							unless external_access.nil? or external_access[idx].nil?
								volume_statement[:external] = external_access[idx] == 'f' ? false : true
							end

              volumes_element[:dispo] = volume.strip
              volumes_element[:link] = volume_statement[:link]

              volumes.push(volumes_element)
              volume_inserts.push(format_volume(volume_statement))
							idx += 1
            end
          elsif !notice['bpi_cote'].blank? and (!notice['bpi_dm_launch'].match(/IdOmm.*@;@/) or !notice['bpi_dm_launch'].match(/.*@;@.*IdOmm/))
            notice['bpi_cote'].split(" @;@ ").each do |cote|
							volume_statement[:note] = note[idx].to_s.strip unless note.nil? or note[idx].nil?
              volume_statement[:call_num] = cote 
              volume_statement[:record_location] = location[idx].to_s.strip unless location.nil? or location[idx].nil?
							volume_statement[:dispo] = 'Disponible'
              if vol_title.blank? or vol_title[idx].blank?
                if label.blank? or label[idx].blank?
                  volume_statement[:label] = title
                else
                  volume_statement[:label] = label[idx] unless label[idx].blank?
                end
              elsif vol_title.kind_of?(String)
                volume_statement[:label] = title
              else
                volume_statement[:label] = vol_title[idx]
              end
              volume_statement[:link] = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_statement[:launch_url] = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_statement[:support] = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_statement[:number] = idx + 1
							unless launchable.nil? or launchable[idx].nil?
								volume_statement[:launchable] = launchable[idx] == '0' ? false : true
							end
							unless external_access.nil? or external_access[idx].nil?
								volume_statement[:external] = external_access[idx] == 'f' ? false : true
							end

              volumes_element[:link] = volume_statement[:link]
              volumes_element[:dispo] = volume_statement[:dispo]

              volumes.push(volumes_element)
              volume_inserts.push(format_volume(volume_statement))
							idx += 1
            end
          elsif notice['bpi_dm_launch'].match(/IdOmm.*@;@/) or notice['bpi_dm_launch'].match(/.*@;@.*IdOmm/)
						exemplaires = notice['bpi_dm_launch'].split(" @;@ ")
            exemplaires.each do |webobj|
							volume_statement[:note] = note[idx].to_s.strip unless note.nil? or note[idx].nil?
              volume_statement[:call_num] = call_num[idx].to_s.strip unless call_num.nil? or call_num[idx].nil? 
              volume_statement[:record_location] = location[idx].to_s.strip unless location.nil? or location[idx].nil?
							volume_statement[:dispo] = 'Consultable sur ce poste'
							volume_statement[:label] = exemplaires.size == 1 ? title : 'Lancer le document'
							volume_statement[:label] = vol_title[idx] unless vol_title.nil? or vol_title[idx].nil?
              volume_statement[:link] = resource_link[idx].strip unless resource_link.nil? or resource_link[idx].nil?
              volume_statement[:launch_url] = launch_url[idx].strip unless launch_url.nil? or launch_url[idx].nil?
              volume_statement[:support] = support[idx].to_s.strip unless support.nil? or support[idx].nil?
              volume_statement[:number] = idx + 1

          		volume_statement[:barcode], volume_statement[:doc_id], volume_statement[:object_id], volume_statement[:source] = ""
              unless bdm_info.nil? or bdm_info[idx].nil?
                volume_statement[:barcode] = bdm_info[idx].match(/barcode=(\d+)/)[1] if bdm_info[idx].match(/barcode=(\d+)/)
                volume_statement[:doc_id] = bdm_info[idx].match(/iddoc=(\d+)/)[1] if bdm_info[idx].match(/iddoc=(\d+)/)
                volume_statement[:object_id] = bdm_info[idx].match(/idomm=(\d+)/)[1] if bdm_info[idx].match(/idomm=(\d+)/) 
                volume_statement[:source] = bdm_info[idx].match(/bdm=([a-z]+)|/i)[1] if bdm_info[idx].match(/bdm=([a-z]+)|/i)
              end
							unless launchable.nil? or launchable[idx].nil?
								volume_statement[:launchable] = launchable[idx] == '0' ? false : true
							end
							unless external_access.nil? or external_access[idx].nil?
								volume_statement[:external] = external_access[idx] == 'f' ? false : true
							end

              volumes_element[:link] = volume_statement[:link]
              volumes_element[:dispo] = volume_statement[:dispo]

              volumes.push(volumes_element)
              volume_inserts.push(format_volume(volume_statement))
							idx += 1
            end  
          end

          # Date for rss feed
					harvesting_date = document_date.blank? ? Time.now : Date.parse(document_date).to_s + "T23:59:59Z"
          
          # Availabilities calculation for each volume
          dispo_sur_poste, dispo_bibliotheque, dispo_access_libre, dispo_avec_reservation = "", "", "", ""
					dispo_broadcast_group = broadcast_groups.blank? ? "" : broadcast_groups.split(";")
          volumes.each do |ex|
            if !resource_link.nil? and defineAvailability(collection.availability, ex[:format]) == "online" 
          		dispo_sur_poste, dispo_bibliotheque, dispo_access_libre, dispo_avec_reservation = 'online', 'online', 'online', 'online'
              break
            elsif ( (ex[:dispo].match(/Disponible/i) or ex[:dispo].match(/bureau/i)) and ( defineAvailabilityDisp(collection.availability, ex[:format]) == "onshelf" or defineAvailabilityDisp(collection.availability, ex[:format]) == "online" ) )
          		dispo_sur_poste, dispo_bibliotheque, dispo_access_libre, dispo_avec_reservation = 'onshelf', 'onshelf', 'onshelf', 'onshelf'
            end
          end
          volumes.clear

          # Save in SOLR
          idD = "#{identifier};#{collection['id']}"
					document = {:id => idD, :collection_id => collection['id'], :controls_id => identifier, :collection_name => collection.name,
						:title => "#{title} #{relation}" ,:creator => "#{creator}; #{normalizePortfolio(notice['bpi_creator2'])}", :subject => subject, 
						:description => description, :publisher => publisher, :keyword => keyword, :theme => theme.split(";"), :theme_rebond => theme, 
						:document_type => type, :harvesting_date => harvesting_date, :isbn => isbn, :issn => issn, :cote_rebond => cote, :bdm_info => bdm_info,
						:autocomplete => keyword, :autocomplete_creator => "#{creator}; #{normalizePortfolio(notice['bpi_creator2'])}", 
						:autocomplete_publisher => publisher, :autocomplete_theme => theme, :autocomplete_title => "#{title} #{relation}", 
						:autocomplete_subject => subject, :autocomplete_description => description, :barcode => barcode_field, :indice => notice['bpi_indice'], 
						:custom_document_type => custom_document_type, :title_sort => UtilFormat.normalize(title), :lang_exact => language, 
						:date_document => UtilFormat.normalizeSolrDate(dcdate), :dispo_sur_poste => dispo_sur_poste, :dispo_bibliotheque => dispo_bibliotheque,
						:dispo_access_libre => dispo_access_libre, :boost => portfolio_revue + BPI_BOOST + UtilFormat.calculateDateBoost(dcdate),
            :dispo_avec_reservation => dispo_avec_reservation, :dispo_broadcast_group => dispo_broadcast_group, :rights => dcrights,
						:location => location, :coverage_spatial => coverage_spatial_index}
					document[:date_end_new] = date_end_new unless date_end_new.nil?
					document[:commercial_number] = commercial_number unless commercial_number.nil?
					document[:musical_kind] = musical_kind unless musical_kind.nil?
					documents.push(document)
					
          update_notice(idD, title, creator, type, "", Time.new)
            
          # Indexing in SOLR every 10K docs 
          if (index > 0 and index % 10000 == 0)
            @index.add(documents)
            documents.clear
          end
          
          # Commit to mysql every 1K docs
          if (index > 0 and index % 1000 == 0)
            insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts, collection.id)
          end
          
          # Commit in SOLR every 10K documents
          if (index > 0 and index % 10000 == 0)
            @logger.info("10000 records ==> ** Committing...")
            commit_start_time = Time.now
            commit
            commit_end_time = Time.now
            commit_duration = commit_end_time - commit_start_time
            @logger.info("10000 records ==> ** Commit Duration : #{commit_duration}")
          end
          
        rescue Exception => e
          nbError += 1
          @logger.error("[portfolio_harvester] #{e.message}")
          @logger.error("[portfolio_harvester] Errors while fetching data : #{$!}. Record title: #{title}\n Record identifier: #{identifier}")
          @logger.error("[portfolio_harvester] Trace : #{e.backtrace.join("\n")}")
        end
        
        index += 1
      end # End of query fetch (begins l.154)
      
      query.finish

			# Last mysql insert and solr commit
      @index.add(documents) unless documents.empty?
    	insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts, collection.id)
    	commit
    	@logger.info("** Last commit...")
    	create_relations(collection.id)
    	Collection.update(collection.id, { :harvested => DateTime.now })
	
  		# Delete removed notices    
      @conn['AutoCommit'] = false
      begin
        @conn.do("LOCK dc_notices_flags IN SHARE UPDATE EXCLUSIVE MODE;")
        nb = @conn.do("DELETE FROM dc_notices_flags WHERE status = 'D';")
        @conn.commit
        @logger.info("[portfolio_harvester] removed #{nb} notices from dc_notices_flags")
      rescue Exception => e
        @conn.rollback
        @logger.error("[portfolio_harvester] error removing deleted notices : #{e.message}")
      end
      @conn['AutoCommit'] = true
      @conn.disconnect

    rescue => err
      Collection.update_all("harvested = NULL", "id = #{collection.id}")

      @logger.error("[portfolio_harvester] Errors : #{$!}")
      @logger.error("[portfolio_harvester] Errors : #{err.message}")
      @logger.error("[portfolio_harvester] Trace : #{err.backtrace.join("\n")}")
			if @replication_activated
				@logger.error("[portfolio_harvester] Switching...")
				switch  
			end
    end
    
		# Harvest ending infos
    begin
		 	Collection.update_all("nb_result = #{index}", "id = #{collection.id}")
			nb_error_max = Parameter.by_name('portfolio_nb_error_max').to_i
			if @replication_activated == '1'
				if nbError >= nb_error_max
					@logger.info("[portfolio_harvester] More than #{nb_error_max} errors! Solr&Mysql replication will not be restarted. Switching...")
					switch
				else
					if @replication_auto  == '1'
						solr_replication('enable')
						mysql_replication('start') 
					else
						@logger.info("[portfolio_harvester] Auto restart replication set to false, replication will not be restarted")
					end
				end
			end
      path = "#{ENV['LIBRARYFIND_HOME']}/log/themes_#{collection.name}_not_match_#{Time.now().to_f}.txt"
      is_write = system("echo #{themePortfolio.indices_no_match.inspect} > #{path}")
      @logger.info("[portfolio_harvester] Finished Indexing : #{index} document(s) indexed!!!")
      @logger.info("[portfolio_harvester] nb errors: #{nbError}/#{index}")
      @logger.info("[portfolio_harvester] Rapport Themes: [Matched: #{themePortfolio.matched}] [No Matched: #{themePortfolio.errors}]")
      @logger.info("[portfolio_harvester] Rapport Themes: [write_file:#{is_write}] For more details, check file: #{path}")
    rescue Exception => e
      @logger.warn("Error writing #{path} : #{e.message}")
    end
    
    total_time_end = Time.now 
    @logger.info("[portfolio_harvester] Process started at #{total_time_start.strftime("%H:%M")}")
    @logger.info("[portfolio_harvester] Process finished at #{total_time_end.strftime("%H:%M")}")
    @logger.info("[portfolio_harvester] Process took #{Time.at(total_time_end - total_time_start).utc.strftime('%H heures et %M minutes')}")
  end

	def switch
		msg = Parameter.switch
		@logger.info "[portfolio_harvester] #{msg} for local machine"

		lf = Parameter.by_name('lf_url')
		harvest = Parameter.by_name('lf_harvesting_url')

		unless lf == harvest
			uri = URI.parse("#{lf}/switch")
			http = Net::HTTP.new(uri.host, uri.port)
			begin
				response = http.request(Net::HTTP::Get.new(uri.request_uri))
				#@logger.info "[Portfolio_harvester] #{response.methods.sort.join("\n").to_s}"
				@logger.info "[Portfolio_harvester] #{response.body} for lf machine (#{lf}"
			rescue Errno::EHOSTUNREACH, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
				@logger.info "[Portfolio_harvester] Couldn't switch mysql&solr for #{lf} machine => #{e.message}"
			end
		end
	end

	def mysql_replication(command)
		mysql1 = Parameter.by_name('mysql1')
		mysql2 = Parameter.by_name('mysql2')
		[mysql2, mysql1].each do |mysql|
			msg = Parameter.mysql_replication(mysql, command)
			@logger.info msg
		end
	end

	def solr_replication(command)
		msg = Parameter.solr_replication(command)
		@logger.info msg
	end

  # Insert data arrays into Mysql (tables metadatas, controls, portfolio_datas and volumes)
  def insert(metadata_inserts, control_inserts, portfolio_data_inserts, volume_inserts, collection)
    transaction_start = Time.now
    ActiveRecord::Base.transaction do
      begin
        if metadata_inserts.size != 0
          @logger.info("Insert: size : metadata_inserts: #{metadata_inserts.size} control_inserts; #{control_inserts.size}")
          @logger.info("portfolio_data_inserts: #{portfolio_data_inserts.size} volume_inserts: #{volume_inserts.size}")

          ActiveRecord::Base.connection.execute("	INSERT INTO controls(oai_identifier, title, collection_id, description, collection_name) 
                                               		VALUES #{control_inserts.join(", ")}")
          ActiveRecord::Base.connection.execute("	INSERT INTO metadatas(collection_id, dc_title, dc_creator, dc_subject,  
                                              		dc_description, dc_publisher, dc_contributor, dc_date, dc_type, dc_format, dc_identifier, 
                                              		dc_relation, dc_coverage, dc_rights, dc_language, dc_coverage_spatial) 
                                              		VALUES #{metadata_inserts.join(", ")}")
          ActiveRecord::Base.connection.execute("	INSERT INTO portfolio_datas(dc_identifier, audience, genre, last_issue, issn, isbn, theme,
                                               		is_available, indice, label_indice, broadcast_group, issues, binding, issue_title, conservation, 
																									commercial_number, musical_kind, publisher_country, abstract) 
                                              		VALUES #{portfolio_data_inserts.join(", ")} ON DUPLICATE KEY UPDATE audience = VALUES(audience), 
																									genre = VALUES(genre), last_issue = VALUES(last_issue), issn = VALUES(issn), isbn = VALUES(isbn), 
																									theme = VALUES(theme), is_available = VALUES(is_available), indice = VALUES(indice), 
																									label_indice = VALUES(label_indice), broadcast_group = VALUES(broadcast_group), issues = VALUES(issues), 
																									binding = VALUES(binding), issue_title = VALUES(issue_title), conservation = VALUES(conservation)")    
          ActiveRecord::Base.connection.execute("	INSERT INTO volumes(dc_identifier, collection_id, availability, call_num, location,
                                              		label, link, launch_url, support, number, barcode, document_id, object_id, source, launchable, note, external_access) 
																									VALUES #{volume_inserts.join(", ")}")
        
          control_inserts.clear
          metadata_inserts.clear
          portfolio_data_inserts.clear
          volume_inserts.clear
        end
      rescue ActiveRecord::Rollback => e
        Collection.update_all("harvested = NULL", "id = #{collection}")
        @logger.error("Transaction has been rolled back => #{e.message}")
      rescue Exception => e
        Collection.update_all("harvested = NULL", "id = #{collection}")
        @logger.error("Error committing documents in MySql => #{e.message}")
        raise e
      end
    end
    transaction_end = Time.now
    @logger.info("Insert transaction total time  => #{transaction_end - transaction_start} seconds.")
  end
  
  # Update MySql to set foreign keys values and relationships  
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
        update_sql = "	UPDATE volumes V SET V.metadata_id = 
												(SELECT M.id FROM metadatas M WHERE M.collection_id = #{collection_id} AND M.dc_identifier = V.dc_identifier)"
        ActiveRecord::Base.connection.execute(update_sql)
        update_sql = "	UPDATE portfolio_datas P SET P.metadata_id = 
												(SELECT M.id FROM metadatas M WHERE M.collection_id = #{collection_id} AND M.dc_identifier = P.dc_identifier)"
        ActiveRecord::Base.connection.execute(update_sql)
        update_end = Time.now
        @logger.info("[PortfolioHarverster][UPDATE SQL] Updates done in #{update_end - update_start} ms")
      rescue ActiveRecord::Rollback => e
        @logger.error("	Uodate transaction has been rolled back => #{e.message}")
      rescue Exception => e
				@logger.error("Error updating relations in MySql => #{e.message}")
        raise e
      end
    end
  end
  
  # Checks for each doc in docs if it's available
  def checkCollectionRecordsAvailability(doc_collection_id, docs)
    docs_available = Array.new
    @logger.info("[portfolio_harvester] DATABASE INFO: " + @db["database"])
    collection = Collection.find_by_id(doc_collection_id)
    begin
      docs_ids = docs.inspect.gsub("\"","'").gsub("[","(").gsub("]",")")
      query = "	SELECT dc_identifier FROM volumes WHERE (dc_identifier IN #{docs_ids}) 
								AND collection_id = #{collection.id} AND availability = 'Disponible'"
      result = Volume.find_by_sql(query)
      result.each do |volume|
        begin
        	docs_available << volume.dc_identifier unless volume.nil?
        rescue => e
          @logger.error("[portfolio_harvester] Errors while fetching data")
          @logger.error("[portfolio_harvester] Trace : #{e.backtrace.join("\n")}")
        end
      end
      return docs_available
    rescue => err
      @logger.error("[portfolio_harvester] Errors : #{err.message}")
      @logger.error("[portfolio_harvester] Trace : #{err.backtrace.join("\n")}")
    end
  end
 
  def defineAvailability(default_collection, value)
		onshelf_patterns = Regexp.union(/papier/i, /microforme/i, /microfilm/i, /imprimé/i)
		online_patterns = Regexp.union(/en ligne/i, /DVD/i, /CD-ROM/i, /\sCD\s/i, /cédérom/i, /internet/i, /vidéo/i)

		result = default_collection
		if value.match(onshelf_patterns)
    	result = 'onshelf'
		elsif value.match(online_patterns)
			result = 'online'
		end
		return result
  end 
  
  def defineAvailabilityDisp(default_collection, value)
		onshelf_patterns = Regexp.union(/papier/i, /microforme/i, /microfilm/i, /imprimé/i)
		result = value.match(onshelf_patterns) ? 'onshelf': default_collection
		return result
  end 

	def format_volume(volume)
			volume = "(	#{sanitize_sql(volume[:identifier])}, #{volume[:id]}, #{sanitize_sql(volume[:dispo])}, #{sanitize_sql(volume[:call_num])},
										#{sanitize_sql(volume[:record_location])}, #{sanitize_sql(volume[:label])}, #{sanitize_sql(volume[:link])},
										#{sanitize_sql(volume[:launch_url])}, #{sanitize_sql(volume[:support])}, #{sanitize_sql(volume[:number])},
										#{sanitize_sql(volume[:barcode])}, #{sanitize_sql(volume[:doc_id])}, #{sanitize_sql(volume[:object_id])},
										#{sanitize_sql(volume[:source])}, #{sanitize_sql(volume[:launchable])}, #{sanitize_sql(volume[:note])}, #{sanitize_sql(volume[:external])} )"
			return volume
	end

end
