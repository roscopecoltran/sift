# -*- coding: utf-8 -*-
# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
#
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with 
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple 
# Place, Suite 330, Boston, MA 02111-1307 USA
#
# Questions or comments on this program may be addressed to:
#
# LibraryFind
# 121 The Valley Library
# Corvallis OR 97331-4501
#
# http://libraryfind.org

class MultipleCollectionSearchClass < ActionController::Base
  
  attr_reader :hits, :xml
  
  @total_hits = 0
  @pid = 0
  @pkeyword = ""
  def self.keyword (_string)
    @pkeyword = _string
  end
  
  def self.insert_id(_id) 
    @pid = _id
  end
  
  def self.helpTheme(hash, indice, number)
    if hash[indice] == nil
        hash[indice] = Array.new()
        hash[indice][0] = number
        hash[indice][1] = Hash.new()
    else
        hash[indice][0] += number
    end
    return hash[indice][1]
  end

  def self.rec_sort(list)
      list.each do |lab, val|
      	val[1] = val[1].sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
	val[1] = self.rec_sort(val[1])
      end
      return list
  end
    
  # Search inside a set of collection by performing a only request to solr     _qoperator, @infos_user, options, qsynonym
  def self.SearchCollection(_collections, _qtype, _qstring, _start, _max, _qoperator, infos_user=nil, options=nil, _qsynonym = nil, _filter = nil) 
    logger.debug("[MultipleCollectionSearchClass] start search")
    _sTime = Time.now().to_f
		
    # We have a get collection by id oftenly. We computed a hash id key to optimize the time :)
    hashCollection = Hash.new
    _collections.each { |item|
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        # Does user have rights to view the notice ?
        droits = ManageDroit.GetDroits(infos_user,item.id)
    
        if (droits.nil?)
          item.id = -1
        end
      end
      hashCollection[item.id] = item
    }
      
    _site = nil 
    _sitepref = nil 
    _keywords = _qstring.join("|")
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] KEYWORD BEFORE PREF: " + _keywords)
  
    if _keywords.index("site:")!= nil 
      _site = _keywords.slice(_keywords.index("site:"), _keywords.length - _keywords.index("site:")).gsub("site:", "")
      _keywords = _keywords.slice(0, _keywords.index("site:")).chop
      if _site.index('"') != nil
        _site = _site.gsub('"', "")
        _keywords << '"'
      end
    elsif _keywords.index("sitepref:") != nil
      _sitepref = _keywords.slice(_keywords.index("sitepref:"), _keywords.length - _keywords.index("sitepref:")).gsub("sitepref:", "")
      logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] SITE PREF: " + _sitepref)
      _keywords = _keywords.slice(0, _keywords.index("sitepref:")).chop
      if _sitepref.index('"') != nil
        _sitepref = _sitepref.gsub('"', "")
        _keywords << '"'
      end
    end
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] KEYWORDs: " + _keywords)
    _calc_keyword = _keywords
    
    # _query = "SELECT DISTINCT CN.id, CN.alt_name, C.id, C.oai_identifier, C.collection_id, C.url, C.title, C.description, M.dc_subject, M.dc_creator, M.dc_date, M.dc_format, M.dc_type, M.osu_thumbnail, M.dc_language, M.dc_relation, M.dc_coverage, M.dc_rights,M.dc_source, M.dc_publisher,M.dc_contributor, M.osu_volume from collections CN LEFT JOIN controls C ON CN.id=C.collection_id  LEFT JOIN metadatas M on C.id = M.controls_id where ("
    _query = "SELECT DISTINCT CN.id, CN.alt_name, C.id, CN.vendor_url,
               C.oai_identifier as oai_identifier, C.collection_id as collection_id, C.url, C.title, C.description, 
               M.id, M.dc_identifier as dc_identifier, M.dc_subject as dc_subject, M.dc_creator as dc_creator, M.dc_date as dc_date, 
               M.dc_format as dc_format, M.dc_type as dc_type, M.osu_thumbnail as osu_thumbnail, M.dc_language as dc_language, 
               M.dc_relation as dc_relation, M.dc_coverage as dc_coverage, M.dc_rights as dc_rights,
               M.dc_source as dc_source, M.dc_publisher as dc_publisher, M.dc_contributor as dc_contributor, 
               M.osu_volume as osu_volume 
               FROM collections CN LEFT JOIN controls C ON CN.id=C.collection_id 
               LEFT JOIN metadatas M on C.id = M.controls_id WHERE "

    _lrecord, dispo_facet_query = RetrieveSolrDocument(_collections, _qtype, _qstring, _qoperator, _start.to_i, _max.to_i, infos_user, options, _qsynonym, _filter)
        
    facette = {}
    if (options["with_facette"]=="1" or options["with_facette"]=="2")
      
      # Pre-calcul des themes
      solr_themes = _lrecord.field_facets("theme_exact");
      theme_hash = Hash.new
      h, path = nil, nil
      solr_themes.each do |solr_theme|
        i = 0
        themes = solr_theme[0].split(THEME_SEPARATOR)
        themes.each do |theme|
					theme.strip!
          if (i == 0)
            path = theme            
            h = self.helpTheme(theme_hash, theme, solr_theme[1])
          elsif (i == themes.length - 1)
            path += " " + THEME_SEPARATOR + " " + theme
            self.helpTheme(h, theme, solr_theme[1])
          else
            path += " " + THEME_SEPARATOR + " " + theme
            h = self.helpTheme(h, theme, solr_theme[1])
          end
          i = i + 1
        end
			end

			if options["tab"] == "MUSIC"
   		  solr_musicals = _lrecord.field_facets("musical_kind_exact")
        musical_hash = Hash.new
        hm, pathm = nil, nil
        solr_musicals.each do |solr_musical|
        i = 0
        musicals = solr_musical[0].split(THEME_SEPARATOR)
        musicals.each do |musical|
 			  	musical.strip!
            if (i == 0)
              pathm = musical           
              hm = self.helpTheme(musical_hash, musical, solr_musical[1])
            elsif (i == musicals.length - 1)
              pathm += " " + THEME_SEPARATOR + " " + musical
              self.helpTheme(hm, musical, solr_musical[1])
            else
              pathm += " " + THEME_SEPARATOR + " " + musical
              hm = self.helpTheme(hm, musical, solr_musical[1])
            end
            i = i + 1
          end
 		    end
			  musical_kinds = musical_hash.sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
			  musical_kinds = self.rec_sort(musical_kinds)
			else
				musical_kinds = []
			end

      # Calcule des facettes online
      disponibilite = Array.new
      online_doc = _lrecord.query_facets(dispo_facet_query[0])
      if online_doc > 0
        disponibilite.push(["online", online_doc])    
      end
      onshelf_doc = _lrecord.query_facets(dispo_facet_query[1])
      if onshelf_doc > 0
        disponibilite.push(["onshelf", onshelf_doc])         
      end

      # Creations des themes
      themes = theme_hash.sort {|a,b| b[1][0].to_i <=> a[1][0].to_i}
      themes = self.rec_sort(themes)

      # Calcul des facettes
      facette = { :material=> _lrecord.field_facets("document_type_exact"),
                  :authors => _lrecord.field_facets("author_exact"),
                  :themes => themes,
                  :availability => disponibilite,
                  :date => _lrecord.dates_facets("date_document", "%Y"),
                  :langs => _lrecord.field_facets("lang_exact"),
                  :databases => _lrecord.field_facets("collection_name_exact"),
                  :subjects => _lrecord.field_facets("subject_exact"),
									:musical_kinds => musical_kinds
      }
        
      if (options["with_facette"]=="2")
        return [], 0, @total_hits, facette
      end

    end

    if (options["with_facette"]=="0" or options["with_facette"]=="1")
      
      _bfound = false;
      joined_ids = ""
      _dateIndexed = Hash.new()
      _Hthemes = Hash.new()
      _dateEndNew = Hash.new()
      _BPIAvailability = Hash.new()
      
      _lrecord.each do |hit|
          id_sql = hit["id"].to_s.split(";")
          _query << "( M.dc_identifier = '#{id_sql[0]}' AND C.collection_id = #{id_sql[1]})  OR "
          joined_ids << ", '#{id_sql[0]}' "
          _dateIndexed[id_sql[0].to_s] = hit["harvesting_date"]
          _Hthemes[id_sql[0].to_s] = hit["theme"]
          _dateEndNew[id_sql[0].to_s] = hit["date_end_new"]
          _bfound = true
       end
      _query = _query.slice(0, (_query.length - 4))
      _query << " ORDER BY FIELD (M.dc_identifier " + joined_ids + ")" 
              
      if _bfound == false 
        logger.error("nothing found for the multiple collection search class ")
        return Array.new, 0, 0, facette
      end
              
      # Query to mysql 
      _results = Collection.find_by_sql(_query) 
                 
      _record = Array.new()
      _i = 0
      _newset = ""
      _trow = nil
      _x = 0
      _oldset = ""
      _newset = ""
      _count = 0
      _tmp_max = 1
      
      _hits = Hash.new()
      _results.each { |_row|
        if hashCollection[_row.collection_id.to_i].is_parent != 1
          _trow = hashCollection[_row.collection_id.to_i]
          if _trow != nil then  
            logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] COLLECTION RESOLVED")
            _newset = _trow.alt_name
            logger.debug('[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] NEW COLLECTION NAME SET' + _newset)
          else
            logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
            _newset = _row.alt_name
          end
        else
          logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] CHECK: " +  _row.collection_id.to_s + ";" + UtilFormat.normalize(_row.oai_identifier))
          _newset = _row.alt_name
        end
        
        if _oldset != ""  
          if  _oldset != _newset
            _hits[_oldset] = _tmp_max-2 
            _count = 0
            _tmp_max = 1
          end
        elsif _oldset == ""
          _count = 0
        end
        
        _record[_x] = self.mapAttribute(_row, hashCollection[_row.collection_id.to_i], _dateIndexed, _sitepref, infos_user, _dateEndNew, _Hthemes)
        _x = _x + 1
        
        _oldset = _newset
        _count = _count + 1
        _tmp_max = _tmp_max + 1 
      }
        if (options["with_facette"]=="0")
          # Calcul des facettes
          facette = { 
            :databases => _lrecord.field_facets("collection_name_exact")
          }
        end
      logger.debug("Record Hits: #{_record.length} sur #{@total_hits}")
      return _record, _record.length, @total_hits, facette
    end

  end
  
  # Create the solr request and return the result
  def self.RetrieveSolrDocument(_collections, _qtype, _qstring, _qoperator, _start, _max, infos_user=nil, options=nil, _qsynonym=nil, _filter = nil)
    
    if LIBRARYFIND_INDEXER.downcase == 'ferret'
      _keywords = UtilFormat.normalizeFerretKeyword(_keywords)
      if _keywords.slice(0,1) != "\""
        if _keywords.index(' OR ') == nil
          _keywords = _keywords.gsub("\"", "'")
        end
      end
      index = Ferret::Search::Searcher.new(LIBRARYFIND_FERRET_PATH)
      queryparser = Ferret::QueryParser.new()
      logger.debug("[OaiSearchClass][RetrieveOAI] KEYWORD: " + _keywords)
      if _is_parent[_coll_list] == 1 
        logger.debug("[OaiSearchClass][RetrieveOAI] IS PARENT")
        raw_query_string = 'collection_id:("' + UtilFormat.normalizeFerretKeyword(_coll_list.to_s) + '") AND ' + _qtype.join("|") + ":(" + _keywords + ")"
        query_object = queryparser.parse(raw_query_string)
        logger.debug("RAW FERRET QUERY: "  + raw_query_string)
        logger.debug("FERRET QUERY: " + query_object.to_s)
      else
        logger.debug("[OaiSearchClass][RetrieveOAI]  NOT PARENT: " + _collection_name[_coll_list])
        _collection_name[_coll_list] = _collection_name[_coll_list].gsub("http_//", "") 
        
        raw_query_string = "collection_name:(\"" + UtilFormat.normalizeFerretKeyword(_collection_name[_coll_list]) + "\") AND " + _qtype.join("|") + ":(" + _keywords + ")"
        query_object  = queryparser.parse(raw_query_string)
        logger.debug("[OaiSearchClass][RetrieveOAI] RAW FERRET QUERY: " + raw_query_string)
        logger.debug("[OaiSearchClass][RetrieveOAI] FERRET QUERY: " + query_object.to_s)
      end
      index.search_each(query_object, :limit => _max) do |doc, score|
        break if score < 0.40
        _query << " controls.id='" + index[doc]["controls_id"].to_s + "' or "
        _bfound = true;
      end 
      index.close
    elsif LIBRARYFIND_INDEXER.downcase == 'solr'
      logger.debug("Entering SOLR")
			conn = Solr::Connection.new(Parameter.by_name('solr_requests'))
      raw_query_string, opt, dispo_facet_query = UtilFormat.generateMultipleRequestSolr(_collections, _qtype, _qstring, _qoperator, _start, _max, options, _qsynonym, _filter, infos_user)
    end
    
    _response = conn.query(raw_query_string, opt)
    @total_hits = _response.total_hits
  
    return _response, dispo_facet_query
  end
  
  def self.mapAttribute(_row, collection, _dateIndexed, _sitepref, infos_user, _dateEndNew, _Hthemes)
    
    record = Record.new()
    _objRec = RecordSet.new()
    
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] Prepping to print Title, etc.")
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] Title: " + UtilFormat.normalize(_row['title']))
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] creator: " + UtilFormat.normalize(_row.dc_creator))
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] date: " + UtilFormat.normalizeDate(_row.dc_date))
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] description: " + UtilFormat.normalize(_row.description))
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] SITE PREF: " + UtilFormat.normalize(_sitepref))
    logger.debug("[MULTIPLE COLLECTION SEARCH CLASS][RetrieveOAI] SITE URL: " + UtilFormat.normalize(_row.url))
    
    
    harvesting_date = _dateIndexed[_row['dc_identifier'].to_s]
    if (!harvesting_date.nil?)
      harvesting_date = DateTime.parse(harvesting_date)
    else
      harvesting_date = ""
    end
    record.date_indexed = harvesting_date
    
    _tmp_type = UtilFormat.normalize(collection.mat_type)
    if _row.dc_type != nil
      _tmp_type = UtilFormat.normalize(_row.dc_type)
    end
    
    record.ptitle = UtilFormat.normalize(_row.title)
    if UtilFormat.normalize(_tmp_type) == 'Article'
      record.title = ""
      record.atitle = UtilFormat.normalize(_row.title)
    else
      record.title =  UtilFormat.normalize(_row.title)
      record.atitle =  ""
    end
    logger.debug("record title: " + record.title)
    record.hits = @total_hits
    record.issn =  ""
    record.isbn = ""
    record.date = UtilFormat.normalizeDate(_row.dc_date)
    record.date_full = _row.dc_date
    record.author = UtilFormat.normalize(_row.dc_creator)
    record.link = ""
    record.id = _row.oai_identifier.to_s + ID_SEPARATOR + _row.collection_id.to_s + ID_SEPARATOR + "0"
    record.doi = ""
    record.openurl = ""
    record.thumbnail_url = UtilFormat.normalize(_row.osu_thumbnail)
    
    if(INFOS_USER_CONTROL and !infos_user.nil?)
      # Does user have rights to view the notice ?
      droits = ManageDroit.GetDroits(infos_user,_row.collection_id)
      record.direct_url = "";
      if (!droits.nil? and !droits.id_perm.nil? and droits.id_perm == ACCESS_ALLOWED)
        record.direct_url = UtilFormat.normalize(_row.url)
      end
    else
      record.direct_url = UtilFormat.normalize(_row.url)          
    end
    
    record.static_url = ""
    record.subject = UtilFormat.normalize(_row.dc_subject)
    record.publisher = chkString(UtilFormat.normalize(_row['dc_publisher']))
    record.callnum = ""
    record.relation = _row['dc_relation']
    record.contributor = _row['dc_contributor']
    record.coverage = _row['dc_coverage']
    record.rights = _row['dc_rights']
    record.format = chkString(UtilFormat.normalize(_row['dc_format']))
    record.availability = collection.availability
    record.lang = UtilFormat.normalizeLang(UtilFormat.normalize(_row.dc_language))
    record.theme = _Hthemes[_row['dc_identifier'].to_s].join(";") if !_Hthemes[_row['dc_identifier'].to_s].blank?
    record.category = ""
    record.identifier = chkString(_row['oai_identifier'])
    record.vendor_url = collection.vendor_url
    record.material_type = PrimaryDocumentType.getNameByDocumentType(_tmp_type, _row.collection_id)
    if record.material_type.blank?
      record.material_type = UtilFormat.normalize(collection.mat_type)
    end
    record.issue = ""
    record.page = ""
    record.number = ""
    record.vendor_name = collection.alt_name
    record.source = _row['dc_source'] if !_row['dc_source'].blank?
    record.publisher = _row['dc_publisher']
    record.contributor = _row['dc_contributor']
    record.volume = _row['osu_volume'] if !_row['osu_volume'].blank?
    _start_time = Time.now()
    record.start = _start_time.to_f
    record.end = Time.now().to_f
    date_end_new = _dateEndNew[_row['dc_identifier'].to_s]
    if (!date_end_new.nil?)
      record.date_end_new = DateTime.parse(date_end_new)
    else
      record.date_end_new = ""
    end
    record.actions_allowed = collection.actions_allowed
    record.issue_title = _row.dc_source

		record.description = UtilFormat.normalize(_row.description)

    # Pour la catalogue BPI
    if collection.conn_type == "portfolio"
      # We need to get the data
      bpi_data = Metadata.find(:all, :conditions=>{:id=>_row['id'].to_i}, :include=>[:volumes, :portfolio_data])
      bpi_data_portofolio = PortfolioData.find(:first, :conditions=>{:metadata_id=>_row['id'].to_i})
      bpi_data_volumes = Volume.find(:all, :conditions=>{:metadata_id=>_row['id'].to_i})
			record.description += ' ' + UtilFormat.normalize(bpi_data_portofolio.attributes['abstract'])
      record.category = bpi_data_portofolio.attributes["genre"]
      record.identifier = ""
      record.binding = bpi_data_portofolio.attributes["binding"]
      record.issue = bpi_data_portofolio.attributes["last_issue"]
      record.label_indice = bpi_data_portofolio.attributes["label_indice"]
      record.issues = bpi_data_portofolio.attributes["issues"].split('@;@').join(';') unless bpi_data_portofolio.attributes["issues"].nil?
      record.availability = defineAvailability(collection.availability, record.format)
      record.issn =  chkString(bpi_data_portofolio.attributes["issn"]) unless bpi_data_portofolio.attributes["issn"].blank?
      record.isbn = chkString(bpi_data_portofolio.attributes["isbn"].split(" @;@ ")[0]) unless bpi_data_portofolio.attributes["isbn"].blank?
      record.is_available = bpi_data_portofolio.attributes["is_available"]
      record.indice = chkString(bpi_data_portofolio.attributes["indice"])
      record.issue_title = bpi_data_portofolio.attributes["issue_title"]
      record.conservation = bpi_data_portofolio.attributes["conservation"]
		  record.commercial_number = bpi_data_portofolio.attributes['commercial_number']
		  record.musical_kind = bpi_data_portofolio.attributes['musical_kind']

      # examplaires
      broadcast_groups = bpi_data_portofolio.broadcast_group.split(";") if !bpi_data_portofolio.broadcast_group.blank?
      #record.examplaires = createExamplaires(bpi_data_volumes, collection.id, infos_user, broadcast_groups)
      record.examplaires = createExamplaires(bpi_data_volumes, collection.id, infos_user, broadcast_groups, record.material_type)
    end
		
    if collection.conn_type == "ged"
      # Does user have rights to view the notice ?
      if(INFOS_USER_CONTROL and !infos_user.nil?)
        droits = ManageDroit.GetDroits(infos_user,collection.id)
        if(!droits.nil? and !droits.id_perm.nil? and droits.id_perm == ACCESS_ALLOWED)
          record.direct_url = transalteUnidEtDonsToUrlGed(record.identifier)
          record.availability = collection.availability
        else
          record.direct_url = "";
          record.availability = ""
        end
      else
        record.direct_url = "";
        record.availability = ""
      end
    end

    return record
  end
    
  # check the state of variables
  def self.chkString(_str)
    begin
      if _str == nil
        return ""
      end
      if _str.is_a?(Numeric)
        return _str.to_s
      end
      return _str.chomp
    rescue
      return ""
    end
  end
  
  def self.createExamplaires(volumes, collection_id=5, infos_user=nil, broadcast_groups = nil, material_type = nil)
  #def self.createExamplaires(volumes, collection_id=5, infos_user=nil, broadcast_groups = nil)
    begin
      array = Array.new
      volumes.each do |v|
				next if v.blank?

        ex = Struct::Examplaire.new()
        v.attributes.each do |var,val|
          a_var = "@#{var}"
          ex.instance_variable_set(a_var, val)
        end
        # Check if access is free or requires reservation
        location_groups = Array.new
        if !infos_user.nil?
          location_groups = ManageRole.GetBroadcastGroups(infos_user)
        end
        if !ex.object_id.blank? and !ex.source.blank? 
          free_groups = FREE_ACCESS_GROUPS.split(",")
					if material_type != 'Vidéo'
						free_groups.each do |group|
							logger.debug("[PortfolioSearchClass] [createExemplaire] group : #{group}\nLocation group : #{location_groups.inspect}\nBROADCAST : #{broadcast_groups.inspect}")
							if !location_groups.nil? and location_groups.include?(group) and broadcast_groups.include?(group)
								ex.availability = "Consultable sur ce poste"
								break
							#elsif location_groups.nil? and broadcast_groups.include?(group)
							#	ex.availability = "Consultable sur un poste de la bibliothèque"
							#	break
							elsif !location_groups.nil? and !location_groups.include?(group) and broadcast_groups.include?(group)
								ex.availability = "Consultable sur un poste en accès libre"
								break
							else
								ex.availability = "Consultable sur poste dédié"
							end
						end
					else
						if infos_user.location_user == 'FILMS_RESA'
							ex.availability = 'Consultable sur ce poste'
						elsif ex.location == 'Niveau 3 - Espace Films'
								ex.availability = 'Consultable sur poste dédié'
								ex.object_id = 0
								ex.source = ''
						else
							if infos_user.location_user == 'PRESSE'
								ex.availability = 'Consultable sur un poste en accès libre'
								ex.object_id = 0
								ex.source = ''
							else
								ex.availability = 'Consultable sur ce poste'
							end
						end
					end
				
				end

        ### Check user rigths
        if(INFOS_USER_CONTROL and !infos_user.nil?)
          # Does user have rights to view the notice ?
          droits = ManageDroit.GetDroits(infos_user, collection_id)
          if(!droits.nil? and !droits.id_perm.nil? and droits.id_perm != ACCESS_ALLOWED)
            ex.object_id = 0
            ex.source = ""
          end
          # Now check display_groups
          logger.debug("[PortfolioSearchClass] [createExemplaire] location_groups : #{location_groups}") 
          if broadcast_groups
            broadcast_groups.each do |broadcast_group|
              logger.debug("[PortfolioSearchClass] [createExemplaire] broadcast_group : #{broadcast_group}")
              if !location_groups.nil? and !location_groups.include?(broadcast_group)  
                ex.object_id = 0
                ex.source = ""
              end
              
            end
          end

          # Now check access type for resource link (inhouse/external access)
          #if !ex.launch_url.blank? 
           # if infos_user.location_user.blank? 
            #  ex.object_id = 0
             # ex.source = ""
              #if ex.availability.match(/Consultable/i) and !ex.link.blank?
               # ex.availability = "Consultable sur ce poste"
              #end              
            #else
              #ex.link = ""
            #end
          #end

				unless ex.launch_url.blank?
					if infos_user.location_user == 'PRO' or infos_user.location_user.blank? or infos_user.location_user == 'EXTERNE' 
						ex.object_id = 0
						ex.source = ''
						if infos_user.location_user.blank? or infos_user.location_user == 'EXTERNE'
							if ex.external_access == false 
								ex.availability = 'Consultable à la Bpi'
								ex.launchable = false
								ex.link = ''
							elsif ex.external_access == true  
								ex.availability = 'Consultable sur ce poste'
								ex.launch_url = ''
							end
						elsif infos_user.location_user == 'PRO'
							ex.launch_url = ''
						end
					end
				end
        end
        array.push(ex)
      end
      return array
    rescue => e
      logger.error("[PortfolioSearchClass] [createExemplaire] error : #{e.message}")
      logger.error("[PortfolioSearchClass] [createExemplaire] error : #{e.backtrace.join("\n")}")
      return []
    end
  end
  
  def self.transalteUnidEtDonsToUrlGed(nuid=nil, dons=nil)
    if nuid==nil
      logger.warn("[transalteUnidToUrlGed] nuidEtDons is nil")
    else
      begin
        if dons==nil
          dons = GED_NAME_FILE
        end
        logger.debug("[transalteUnidToUrlGed] nuidEtDons is " + nuid + " and dons=" + dons)
        _hexa = nuid.to_i.to_s(16)
        logger.debug("[transalteUnidToUrlGed] code hexa is " + _hexa)
        _diff = GED_NB_CAR_REP.to_i - _hexa.to_s.length
        logger.debug("[transalteUnidToUrlGed] diff = " + _diff.to_s)
        
        if (_diff >= 0)
          _diff.times { |i|
            _hexa = "0" + _hexa.to_s
          }
          logger.debug("[transalteUnidToUrlGed] code hexa is " + _hexa.to_s)
          _pathDocument = ""
          i = 1
          _hexa.to_s.each_char { |car|
            _pathDocument = _pathDocument + car
            
            if i%2 == 0
               _pathDocument = _pathDocument + GED_URL_SEPARATOR
            end
            i = i + 1
          }
          _url = ""
          logger.debug("[transalteUnidToUrlGed] code _pathDocument is " + _pathDocument.to_s)
          _url = GED_URL_PATH + _pathDocument + dons
          logger.debug("[transalteUnidToUrlGed] url final is " + _url.to_s)
          return _url
        else
            logger.error("[transalteUnidToUrlGed] the difference is negative, see the variable GED_NB_CAR_REP [hexa:" + _hexa + " GED_NB_CAR_REP:" + GED_NB_CAR_REP + "]")
        end
      rescue
        logger.error("Error in transalteUnidEtDonsToUrlGed #{$!}")
      end 
    end
    return nil;
  end
  
	def self.defineAvailability(default_collection, value)
	  if value.blank?
	    return default_collection
	  end
   
    if value.match(/en ligne/i)
      return "online"
    elsif value.match(/DVD/i)
      return "online"
    elsif value.match(/CD-ROM/i)
      return "online"
    elsif value.match(/\sCD\s/i)
      return "online"
    elsif value.match(/cédérom/i)
      return "online"
    elsif value.match(/internet/i)
      return "online"
    elsif value.match(/vidéo/i)
      return "online"
    elsif value.match(/papier/i)
      return "onshelf"
    elsif value.match(/microforme/i)
      return "onshelf"
    elsif value.match(/microfilm/i)
      return "onshelf"
    elsif value.match(/imprimé/i)
      return "onshelf"
    else
      return default_collection
    end
 end 
 

 	def self.defineAvailabilityDisp(default_collection, value)
   if value.blank?
     return default_collection
   end
   
   if value.match(/papier/i)
     return "onshelf"
   elsif value.match(/microforme/i)
     return "onshelf"    
   elsif value.match(/microfilm/i)
     return "onshelf"    
   elsif value.match(/imprimé/i)
     return "onshelf"
   else
     return default_collection
   end
 end 
  
end
