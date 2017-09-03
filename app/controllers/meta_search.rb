# -*- coding: utf-8 -*-
# $Id: MetaSearch.rb 386 2006-09-01 23:34:07Z dchud $

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

require 'monitor'
require 'solr'
require 'solr/request_spellcheck.rb'
require 'solr/response_spellcheck.rb'

class MetaSearch < ActionController::Base
  #========================================================
  #_sets is a hash -- format passed should be
  # :set => 'oasis;aph',
  # :group => 'image'
  # _query == value returned from using the 
  # _params = hash containing info
  # :start => 0
  # :max => 10
  # :force_reload => 1 (to force reload)
  # :session => 'session number' (only present if needed)
  #=========================================================
  def initialize
    super
    logger.debug("[MetaSearch][initialize]")
    @infos_user = nil
  end
    
  # _sets :         query_sets (collection_groups)
  # _qtype:         table (creator, title, ...)
  # _qstring :      table of keywords (string1, string2, string3)
  # _start :        begin search by 0 (DEFAULT) or _start
  # _max :          max result by search
  # _qoperator :    table of operators (operator1, operator2)
  def SolrSearch (_sets, _qtype, _qstring, _start, _max, _qoperator, _filter, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true) 

    logger.info("[SearchAsync] INFOS_USER_CONTROL : #{INFOS_USER_CONTROL} @infos_user : #{@infos_user.inspect}")
        
    _sTime = Time.now().to_f
    
    logger.debug("[SearchAsync] keyword:#{_qstring[0]}")
    logger.debug("[SearchAsync] keyword:#{_qstring.inspect}")
    
    # search collection for the set id
    logger.debug("[SearchAsync] search collection #{_sets.to_s}")
  
    _collections_async = Collection.find_resources(_sets, true)
      #_collections_sync = Collection.find_resources(_sets, false, true)
  
    # We search all the synonyms for a word  
    # The qsynonym will be used in the UtilFormat:MultifieldOrganize function 
    qsynonym = expand_query_with_synonyms(_qstring, _qtype)
    logger.debug("[SearchAsync] SearchAsync _qstring : #{_qstring.inspect}")
    
    # Recherche dans les collections asynchrones
    record=SearchInsideMultipleCollection(_collections_async, _qtype, _qstring, _start, _max, _qoperator, _filter, options, _session_id, _action_type, _data, _bool_obj, qsynonym)
       
    # Recherche dans les collections synchrones
    #myjobs.concat(SearchInsideCollection(_collections_sync, _qtype, _qstring, _start, _max, _qoperator, performance, options, _session_id, _action_type, _data, _bool_obj, qsynonym))
  
    logger.debug("[SearchAsync] finish")
    logger.warn("#STAT# [RETRIEVE] SearchAsync " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    return record
  end


  def addLogConsultSolr(logs, ids)
     @log_management.logs(logs, ids)
  end
  
  # This method is specially make for asynchrone collection.
  # This create a special query and 
  def SearchInsideMultipleCollection(_collections, _qtype, _qstring, _start, _max, _qoperator, _filter, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true, qsynonym = nil)
    
    if(INFOS_USER_CONTROL and !@infos_user.nil?)
      # Get collections list in which the user is authorized to search
      collections_permissions = ManageDroit.GetCollectionsAndPermissions(@infos_user)
      cols_ids_authorized = Collection.getCollectionsIds(collections_permissions)
    end
    return MultipleCollectionSearchClass.SearchCollection(_collections, _qtype, _qstring, _start.to_i, _max.to_i, _qoperator, @infos_user, options, qsynonym, _filter)
    
  end
  
  # _sets :         query_sets (collection_groups)
  # _qtype:       table (creator, title, ...)
  # _qstring :    table of keywords (string1, string2, string3)
  # _start :        begin search by 0 (DEFAULT) or _start
  # _max :          max result by search
  # _qoperator :  table of operators (operator1, operator2)
  def SearchSync (_sets, _qtype, _qstring, _qoperator, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true, _memcache = nil) 
    logger.debug("[SearchAsync] INFOS_USER_CONTROL : #{INFOS_USER_CONTROL} @infos_user : #{@infos_user.inspect}")
        
    _sTime = Time.now().to_f
    
    logger.debug("[SearchAsync] keyword:#{_qstring[0]}")
    logger.debug("[SearchAsync] keyword:#{_qstring.inspect}")

    # set max by collection if it's not set
#    if _max == nil 
#      _max = MAX_COLLECTION_SEARCH
#    end
    
    # search collection for the set id
    logger.debug("[SearchAsync] search collection #{_sets.to_s}")

#    no_externe = false
#    if (!options.nil?)
#      no_externe = true
#    end
    _collections = Collection.find_resources(_sets, false)
 
    # We search all the synonyms for a word  
    # The qsynonym will be used in the UtilFormat:MultifieldOrganize function 
    qsynonym = expand_query_with_synonyms(_qstring, _qtype)
    logger.debug("[SearchAsync] SearchAsync _qstring : #{_qstring.inspect}")
    
    myjobs = []

    myjobs.concat(SearchInsideCollection(_sets, _collections, _qtype, _qstring, _qoperator, options, _session_id, _action_type, _data, _bool_obj, qsynonym, _memcache))
    
    logger.debug("[SearchAsync] finish")
    logger.warn("#STAT# [RETRIEVE] SearchAsync " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
    return myjobs
  end
  
 # This method is done to start a thread for each collection in _collections
 # This is no for performance mode...
 # This methode can also be used for synchronous collections
 def SearchInsideCollection(_sets, _collections, _qtype, _qstring, _qoperator, options=nil, _session_id=nil, _action_type=1, _data = nil, _bool_obj=true, qsynonym = nil, _memcache = nil)
   
   spawn_ids = []
   myjob = []
   _objCache = []
     
   _objRec = RecordSet.new
   _objRec.setKeyword( _qstring[0])
   _max_recs = 0
     
   if(INFOS_USER_CONTROL and !@infos_user.nil?)
     # Get collections list in which the user is authorized to search
     collections_permissions = ManageDroit.GetCollectionsAndPermissions(@infos_user)
     cols_ids_authorized = Collection.getCollectionsIds(collections_permissions)
   end
   
   #================================================
   # Check the cache
   #================================================
   _search_id = nil
   _my_search_id = nil
   
   # Has this search been run before?  Return the matching row as array if so 
   logger.debug("[SearchAsync] IS THIS FIXED: " + _qstring.join("|").to_s)
 
  if _memcache.nil?
	   # On check si la requete a deja été faite et est en cache
  	 cached_recs, value = CachedSearch.check_cache(_qstring, _qtype, _sets, @infos_user )
   else
	   # Initialisation des variables cached_recs et value à nil au cas où on n'utilise pas le cache
		 cached_recs = nil
		 value = nil
	 end


   data_are_in_cache = false
   if cached_recs.nil? || (!cached_recs.nil? and cached_recs.empty?)
     # _last_id is generated when this search is saved
     _search_id = CachedSearch.set_query(_qstring, _qtype, _sets, @infos_user)
     data_are_in_cache = false
   else  
     #if CACHE_ACTIVATE
       data_are_in_cache = true
       _search_id = cached_recs  
       #_last_id = cached_recs
#     else
#       # _last_id is the id of the matching search
#       _last_id = cached_recs[0].id
#       # _search_id starts with same id, but is modified later
#       _search_id = cached_recs[0].id
#       # _max_recs is the saved number of hits per collection 
#       # (which might be insufficient)
#       _max_recs = cached_recs[0].max_recs
#     end
   end
   
   # Pour chaque collection
   _collections.each_index { |_index|
     #================================================
     # If in Cache -- extract data from the cache
     # and return
     #================================================
     if _collections[_index] == nil
       next;
     end
     
     # test si collection is private
     _is_private = false
     
     if(INFOS_USER_CONTROL and !@infos_user.nil?)
       if !cols_ids_authorized.include?(_collections[_index].id) or _collections[_index]['is_private'] == 1
         _is_private = true
       end
     end
     
     job_id = JobQueue.create_job(_collections[_index].id)
     if (!job_id.nil?)
       logger.debug("[SearchAsync] create job ; #{_collections[_index].id} ==> #{job_id}")
       myjob[_index] = job_id
     else
       logger.error("[SearchAsync] #{_collections[_index].id} ==> job id nil")
       next
     end
     logger.debug("[SearchAsync] call spawn")
     
     # Pour chaque swpawn_ids
     spawn_ids[_index] = spawn do
       #_pre_filtered_search = false
       _myqstring = Array.new(_qstring)
       #Adding the ability to filter query by collection
#       if !_collections[_index].filter_query.blank?
#         _myqstring << _collections[_index].filter_query
#         _pre_filtered_search = true
#       end   
#       
#       if !options.nil? and options.size > 2 and !options["query"].blank?
#         _pre_filtered_search = true
#         _myqstring << options["query"]
#       end
       
#       if _pre_filtered_search 
#         logger.debug("[SearchAsync] Entering in pre filtered search mode")
#         _my_search_id, my_cached_recs = CachedSearch.check_cache(_myqstring, _qtype, _sets, _max, @infos_user)
#         if my_cached_recs.nil? #or my_cached_recs.length==0 
#           _my_last_id = CachedSearch.set_query(_myqstring, _qtype, _sets, _max.to_i, @infos_user)
#         else
#           if CACHE_ACTIVATE
#             _my_last_id = _my_search_id
#             _my_max_recs = my_cached_recs
#           else
#             _my_last_id = my_cached_recs[0].id
#             _my_search_id = my_cached_recs[0].id
#             _my_max_recs = my_cached_recs[0].max_recs
#           end
#         end
#       end
       
       if !INFOS_USER_CONTROL or @infos_user.nil? or (INFOS_USER_CONTROL and cols_ids_authorized.include?(_collections[_index].id))
         logger.debug("[SearchAsync] Updating job")
         JobQueue.update_job(myjob[_index], nil, _collections[_index].alt_name, JOB_WAITING) 
         #_objCache[_index] = CacheSearchClass.new()
         
         ############################################################################
         # Create a new search cache for the prefiltered search query
         ############################################################################
#         if _pre_filtered_search
#           logger.debug("[SearchAsync] Searching in pre filtered database cache")
#           _s_id = _my_search_id
#         else
#           logger.debug("[SearchAsync] Searching in normal database")
#           _s_id = _search_id
#         end
         
         #cache = true
         #if (!options.nil?)
           #cache = false
         #else
           #_objCache[_index].SearchCollection(_objRec, _collections[_index].id, _s_id, _collections[_index].nb_result, myjob[_index], @infos_user,options)
           #            _objCache[_index].SearchCollection(_objRec, _collections[_index].id, _s_id, _max.to_i, myjob[_index], @infos_user,options)
         #end
         ############################################################################
         
         if data_are_in_cache == true  #&& _objCache[_index].records != nil
           
           logger.debug("[SearchAsync] spawn process to found in thread : " + myjob[_index].to_s)
           # need to mark query as finished.
           _job_etat = JOB_FINISHED
           if _is_private == true
             _job_etat = JOB_PRIVATE
           end
#           if !_objCache[_index].records.empty?
#             h = _objCache[_index].records[0].hits
#           else
#             h = 0
#           end
            if @infos_user and !@infos_user.location_user.blank?
              key = "#{_search_id}_#{_collections[_index].id}_#{@infos_user.location_user}"
            else
              key = "#{_search_id}_#{_collections[_index].id}"
            end

           JobQueue.update_job(myjob[_index],"#{key}", _collections[_index].alt_name, _job_etat, 0, 0)
           
         #elsif cache && _objCache[_index].is_in_cache == true && _objCache[_index].records == nil
           # no records were found in the search -- results are zero
           #logger.debug("[SearchAsync] result in cache but results are zero")
           #JobQueue.update_job(myjob[_index], _objCache[_index].records_id, _collections[_index].alt_name, JOB_FINISHED, 0)
         else
           # no cache, so search now
           # No matching search found  
           begin
             logger.debug("[SearchAsync] start time")
             _start_thread = Time.now().to_f
             my_id = 0
             my_hits = 0
             total_hits = 0
             
             # Why this test ? i don't know
             if _qstring.join(" ").index("site:") != nil and _collections[_index].conn_type != 'oai'
               tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, JOB_FINISHED, 0) 
               next
             end
             
             # change id if filter search
             _s_id = _search_id
             #if _pre_filtered_search
              # _s_id = _my_last_id
             #end
             
             # normalize string if not oai et connector
             _q = _qstring
             if _collections[_index].conn_type != 'oai' and _collections[_index].conn_type != 'connector'
               _q = pNormalizeString(_qstring)
             end
             
             
             logger.info("[SearchAsync] _q.inspect = #{_q.inspect}")
             # determine search class (using oai_set field info if connection type = connector (custom connector)
             _search_class = _collections[_index].conn_type.capitalize
             if _collections[_index].conn_type == 'connector'
               _search_class = _collections[_index].oai_set.capitalize
             end
             
             logger.debug("[SearchAsync] INDEXER: " + LIBRARYFIND_INDEXER)
             logger.debug("[MetaSearch][SearchAsync] - Query string: " + _q.join(" "))
             logger.debug("[METASEARCH] : Search class = #{_search_class}")
             rescued = false
             begin
               eval("my_id, my_hits, total_hits = #{_search_class}SearchClass.SearchCollection(_collections[_index], _qtype, _q, 0, _collections[_index].nb_result, _qoperator, _s_id, myjob[_index], @infos_user, options, _session_id, 1, _data, _bool_obj, qsynonym)")                
             rescue => e
               logger.error("[METASEARCH] : Search class = #{e.message}")
               logger.error("[METASEARCH] backtrace = #{e.backtrace}")
               raise e
             end
             # set finish time
             _end_thread =  Time.now().to_f - _start_thread
             #CachedSearch.save_execution_time(_s_id, _collections[_index].id, _end_thread.to_s, @infos_user)
             
             logger.debug("[SearchAsync] My_ID = #{my_id.to_s} for collection #{_collections[_index]}")
             if my_id != nil
               # Set the job id message for finished.
               logger.debug("[SearchAsync] Updating status: " + " jobid: " + myjob[_index].to_s + " myid: " + my_id.to_s)
               _job_etat = JOB_FINISHED
               if _is_private == true
                 _job_etat = JOB_PRIVATE
               end
               
               #if ((total_hits.to_i < my_hits.to_i) or (total_hits.to_i < _max.to_i) or (total_hits.to_i > _max.to_i and my_hits.to_i != _max.to_i))
                 #total_hits = my_hits
               #end
               tmpreturn = JobQueue.update_job(myjob[_index], my_id, _collections[_index].alt_name, _job_etat, my_hits, total_hits)
               logger.debug("[SearchAsync] return value from update: " + tmpreturn.to_s)
             else
               # Set the job id message for error; 
               logger.error("[SearchAsync] Unable to establish/maintain a connection to the resource #{_collections[_index].alt_name}")
               JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR, -1, 0, "Unable to establish/maintain a connection to the resource")
             end 
             
           rescue ArgumentError => er
             logger.error("[SearchAsync] error :" + er.message)
             JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR_TYPE, -1, 0, er.message)
           rescue Exception => bang
             logger.error("[SearchAsync] error :" + bang.message)
             logger.error("[SearchAsync] " + bang.backtrace.join("\n"))
             JobQueue.update_job(myjob[_index], -1, _collections[_index].alt_name, JOB_ERROR, -1, 0, bang.message)
           end
         end
       else
         # case collection no rigth to search
         JobQueue.update_job(myjob[_index], nil, _collections[_index].alt_name, JOB_PRIVATE, -1, 0, "No right for this base")
       end
       
     end
     # Update the thread_ids to the job
     #
     logger.debug("[SearchAsync] job id: " + myjob[_index].to_s)
     logger.debug("[SearchAsync] spawn handle id: " + spawn_ids[_index].handle.to_s)
     logger.debug("[SearchAsync] spawn id: " + spawn_ids[_index].to_s)
     logger.debug("[SearchAsync] index: " + _index.to_s)
     JobQueue.update_thread_id(myjob[_index], spawn_ids[_index].handle)
   }  
   
   return myjob
 end
 
 
  # Search for the synonym of a keyword in solr
  # Return an array for each keyword
  def expand_query_with_synonyms(_query, _qtype)
		conn = Solr::Connection.new(Parameter.by_name('solr_requests'))
    synonyms = Array.new 
    idx = 0
    begin
      _query.each do |term|
        response = conn.query("searcher:(#{UtilFormat.normalizeSolrKeyword(term)})")
        logger.debug("[MetaSearch][expand_query_with_synonyms] response #{response.inspect}")
        synonyms[idx] = Array.new
        response.each do |row|
          row["searcher"].each do |item|
            synonyms[idx].push(item.chomp)
          end
        end
        idx += 1
      end
    rescue => e
      logger.error("[MetaSearch][expand_query_with_synonyms] Error " + e.message)
    end
    return synonyms
  end
  
  # pass a list of job ids and 
  # then deal with it
  def CheckJobStatus(_ids)
    objJobs = [] 
    i = 0
    case _ids.class.to_s
      when "Array"
      results = JobQueue.check_status(_ids)
      if !results.nil?
        results.each do |tmpobj|
          if tmpobj != nil
            objJobs[i] = JobItem.new()
            objJobs[i].job_id = tmpobj.id
            objJobs[i].record_id = tmpobj.records_id
            objJobs[i].thread_id = tmpobj.thread_id
            objJobs[i].target_name = tmpobj.database_name
            objJobs[i].hits = tmpobj.hits
            objJobs[i].total_hits = tmpobj.total_hits
      	    if (objJobs[i].hits > objJobs[i].total_hits)
                     objJobs[i].total_hits = objJobs[i].hits
      	    end
            objJobs[i].status = tmpobj.status
            objJobs[i].error = tmpobj.error
            objJobs[i].timestamp = tmpobj.timestamp
            i = i + 1
          end
        end
      end
      return objJobs
      
    else
      tmpobj = JobQueue.check_status(_ids)
      logger.debug("[CHECKJOBSTATUS] Classe tmpobj = #{tmpobj.class.to_s}")
      if !tmpobj.nil?
        objJobs[i] = JobItem.new()
        objJobs[i].job_id = tmpobj.id
        objJobs[i].record_id = tmpobj.records_id
        objJobs[i].thread_id = tmpobj.thread_id
        objJobs[i].target_name = tmpobj.database_name
        objJobs[i].hits = tmpobj.hits
        objJobs[i].total_hits = tmpobj.total_hits
        objJobs[i].status = tmpobj.status
        objJobs[i].error = tmpobj.error
        objJobs[i].timestamp = tmpobj.timestamp
        return objJobs[i]
      else
        return JobItem.new()
      end
    end
    
  end
  
  # Retrieve the individual job records.
  # this basically is just an extraction from the cache
  def GetJobRecord(job_id,  _max)
    logger.debug("[meta_search][GetJobRecord] get job record id #{job_id}")
    _objRec = RecordSet.new
    _xml = JobQueue.retrieve_metadata(job_id, _max, 86400, @infos_user)
    logger.debug("[meta_search][GetJobRecord] cached search xml return object = #{_xml.class}")
    if _xml != nil
      if _xml.status == LIBRARYFIND_CACHE_OK
        # Note:  it should never happen that .data is nil
        if _xml.data != nil
          return _objRec.unpack_cache(_xml.data, _max.to_i)
        end
      end
    end
    return nil
  end 
  
  def KillThread(job_ids, thread_id = nil)
    if thread_id.nil?
      logger.info("[MetaSearch][KillThread] killing jobs #{job_ids}")
      job_ids.each do |job_id|
        job = JobQueue.find_by_id(job_id)
        if job.status > 0
          begin
            if (job.thread_id.to_i > 0) 
              JobQueue.transaction do 
                Process.kill("KILL", job.thread_id)
              end
            end
          rescue Exception => e
            logger.error("[MetaSearch][KillThread] error #{e.message}")
          ensure
            logger.error("[MetaSearch][KillThread] updating job #{job_id}")
            JobQueue.update_job(job_id, 0, nil, -3, 0, 0)
            return 0
          end
        end
      end
    elsif (thread_id.to_i > 0) 
      JobQueue.transaction do 
        JobQueue.update_job(job_ids, 0, nil, -3, 0, 0)
        Process.kill("KILL", thread_id)
      end
    end
  end 
  
  def GetJobsRecords(job_ids)
      
    _sTime = Time.now().to_f
    _recs = Array.new();
    _tmp = Array.new();
    _objRec = RecordSet.new
    _rec = Record.new
    job_ids.each do |_id|
      
      # verification si dans le temps
      #objJob = JobQueue.getJobInTemps(_id, temps)
      #if (objJob.nil?)
        #next
      #end
      
#      if CACHE_ACTIVATE
#        tmp = nil
#        if @infos_user and !@infos_user.location_user.blank?
#          cle = "#{_id}_#{@infos_user.location_user}"
#        else
#          cle = "#{_id}"
#        end
#        begin
#          tmp = CACHE.get(cle)
#          if !tmp.blank?
#            _recs.concat(tmp)
#            next
#          end
#        rescue => e
#          logger.error("[GetJobsRecords] Error when get memcache: #{cle}: #{e.message}")
#        end
#      end
      
      _xml, cle = JobQueue.retrieve_metadata(_id, @infos_user)
      if _xml != nil
        if _xml.status == LIBRARYFIND_CACHE_OK
          # Note:  it should never happen that .data is nil
          if _xml.data != nil
            #logger.debug("XML to UNPACK: " + _xml.data)
            # Load from cache
            _tmp =  _objRec.unpack_cache(_xml.data)
            if _tmp != nil
#              if CACHE_ACTIVATE
#                logger.info("[GetJobsRecords] Set in cache with key = #{cle}")
#                begin
#                  CACHE.set(cle, _tmp, 3600.seconds)
#                rescue
#                  logger.error("[GetJobsRecords] error when writing in cache")
#                end
#              end
              _recs.concat(_tmp)
            end
          end
        end
      end
    end
    
    logger.debug("#STAT# [GETRECORDS] total: " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    return _recs;
  end
  
  def GetTotalHitsByJobs(jobs_ids)
    return JobQueue.total_hits_by_jobs(jobs_ids)
  end
  
  def ListGroupsSyn(id_CG, tab_name)
    if !tab_name.blank?
      return CollectionGroup.findByTabNameAndType(tab_name)
    else
      if (id_CG.blank?)
        return CollectionGroup.find_all_by_collection_type(SYNCHRONOUS_GROUP_COLLECTION)
      else
        return CollectionGroup.find_by_collection_type_and_id(SYNCHRONOUS_GROUP_COLLECTION, id_CG)
      end     
    end
  end

  def ListCollections()
    objList = []
    objCollections = Collection.get_all()
    objCollections.each do |item|
      objCollectionList = CollectionList.new()
      objCollectionList.id = "c" + item.id.to_s
      objCollectionList.name = item.alt_name
      objMembers = CollectionGroup.get_parents(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "g" + coll.collection_group_id.to_s
        tmpvals = CollectionGroup.get_item(coll.collection_group_id)
        if tmpvals != nil
          arrNames << tmpvals
        else
          arrNames << "[undefined]"
        end
      end
      objCollectionList.member_ids = arrIds
      objCollectionList.member_names = arrNames
      objList << objCollectionList  
    end   
    return objList
  end
  
  def ListGroups(bool_advanced=false)
    objList = []
    objGroups = CollectionGroup.get_asynchronous_collection(bool_advanced)
    objGroups.each do |item|
      objGroupList = GroupList.new()
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objGroupList.internal_name = item.name
      objGroupList.type = item.collection_type
      objGroupList.rank = item.rank
      objMembers = CollectionGroup.get_members(item.id)
			if @infos_user.location_user == 'EXTERNE'
				external_collections_ids = ManageDroit.external_collections
				objMembers.reject! {|member| !external_collections_ids.include? member.collection_id}
			end
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
        tmpvals = Collection.get_item(coll.collection_id)
        if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
          arrNames << "[undefined]"
        end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
      objGroupList.id_tab = item.tab_id
      if (item.tab_id != 0)
        objGroupList.tab_name = SearchTab.find(:first, :conditions => "id = #{item.tab_id}").label
      else
        objGroupList.tab_name = ""
      end
      objGroupList.description = item.description
      objList << objGroupList
    end 
    return (objList);
  end
  
  def ListAlpha(tab_id)
    objGroups = CollectionGroup.get_list_alpha_id(tab_id)
    if (!objGroups.blank?)
      objAlpha = "g" + objGroups[0].id.to_s
    else
      objAlpha = nil
    end
    return objAlpha  
  end 
  
  def GetGroupMembers(name)
    objGroupList = GroupList.new()
    objGroups = CollectionGroup.get_item_by_name(name)
    objGroups.each do |item|
      objGroupList.id = "g" + item.id.to_s
      objGroupList.name = item.full_name
      objMembers = CollectionGroup.get_members(item.id)
      arrIds = []
      arrNames = []
      objMembers.each do |coll|
        arrIds << "c" + coll.collection_id.to_s
        tmpvals = Collection.get_item(coll.collection_id)
        if tmpvals != nil
          arrNames << Collection.get_item(coll.collection_id)
        else
          arrNames << "[undefined]"
        end 
      end
      objGroupList.member_ids = arrIds
      objGroupList.member_names = arrNames
    end
    return objGroupList
  end
  
  def GetId(id, logs = {})
    logger.debug("[MetaSearch][GetId] id: #{id}")
    if id.blank?
      return nil
    end
    arr = id.split(";")
    
    begin
      _doc = MetaDisplay.new
      _r = _doc.display(arr[0], arr[1], arr[2], @infos_user)
      if !_r.nil?
        _r.id = id
        @log_management.logs(logs, _r)          
        return _r
      end
      
    rescue => err
      logger.error("[MetaSearch] [GetId] error: #{err.message}")
      logger.error("[MetaSearch] [GetId] error: #{err.backtrace.join('\n')}")
    end
    
    return nil 
  end
  
  def pNormalizeString(_qstring)
    _tqstring = Array.new(_qstring)
    _tmpsite = ""
    i = 0
    while i != _tqstring.length
      if _tqstring[i].index("site:")!= nil
        _tmpsite = _tqstring[i].slice(_tqstring[i].index("site:"), _tqstring[i].length - _tqstring[i].index("site:")).gsub("site:", "")
        _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("site:")).chop
        if _tmpsite.index('"') != nil
          _tqstring[i] << '"'
        end
      elsif _tqstring[i].index("sitepref:") != nil
        _tmpsite = _tqstring[i].slice(_tqstring[i].index("sitepref:"), _tqstring[i].length - _tqstring[i].index("sitepref:")).gsub("sitepref:","")
        _tqstring[i] = _tqstring[i].slice(0, _tqstring[i].index("sitepref:")).chop
        if _tmpsite.index('"') != nil
          _tqstring[i] << '"'
        end
      end 
      i = i+1
    end
    logger.debug("[MetaSearch][pNormalizeString] - string = #{_tqstring.inspect}")
    return _tqstring
  end
  
  def GetTabs()
    objList      = []
    objTabsList  = SearchTab.find(:all);
    
    objTabsList.each do |item|
      objTabList       = TabList.new();
      objTabList.id    = item.id;
      objTabList.name  = item.label;
      objTabList.description = item.description;
      
      objList << objTabList;
    end
    return objList;
  end
  
  def GetFilter()
    objList         = []
    objFiltersList  = SearchTabFilter.find(:all);
    
    objFiltersList.each do |item|
      objFilterList              = FilterList.new();
      objFilterList.id_tab       = item.search_tab_id;
      objFilterList.name         = item.label;
      objFilterList.filter       = item.field_filter;
      objFilterList.description  = item.description;
      objFilterList.id           = item.id
      objList << objFilterList;
    end
    return objList;
  end
  
  def topTenMostViewed()
    return LogConsult.topConsulted()
  end
  
  def getCollectionAuthenticationInfo(collection_id)
    result = Hash.new
    collection = Collection.find_by_id(collection_id)
    logger.debug("[metaSearch][getCollectionAuthenticationInfo] HOST : #{collection.host}")
    result["post_data"] = collection.post_data
    result["action"] = collection.host
    return result
  end
  
  def getTheme(t)
    theme = SearchTabSubject.new();
    tabs  = self.GetTabs();
    i     = 0;
    
    while ((!tabs[i].name.nil?) && 
     (!t.nil?) &&
     (tabs[i].name!=t))
      i += 1
      logger.debug("[metaSearch][getTheme] boucle : " + tabs[i].name)
    end
    if (!tabs[i].id.nil?) 
      t = tabs[i].id
    end
    logger.debug("[metaSearch][getTheme] theme : '" + t.to_s + "'")
    return theme.CreateSubMenuTree(t);
  end
  
  def autoComplete(word, field)
    if (word.blank?)
      autocomplete_res  = []
    else
      autocomplete_res  = Array.new;
      texte             = word.downcase;
      texte             = UtilFormat.remove_accents(texte)
      address           = Parameter.by_name('solr_requests') + "/autocomplete?terms.prefix=#{texte}&terms.lower.incl=false&terms.regex=#{texte}([^;_]*)&terms.regex.flag=case_insensitive";
      if (!field.blank? and field != 'keyword' )
        address         += "&terms.fl=autocomplete_" + field;
      end
      address           = URI.escape(address);
      _sRTime           = Time.now().to_f;
      response          = Net::HTTP.get_response(URI.parse(address));
      logger.debug("#STAT# [AUTOCOMPLETE] requete: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS;
      case (response)
        when Net::HTTPSuccess
          response.body;
          _xpath = Xpath.new();
          parser = ::PARSER_TYPE;
          case (parser)
            when 'libxml'
            _parser         = LibXML::XML::Parser.new();
            _parser.string  = response.body;
            _xml            = LibXML::XML::Document.new();
            _xml            = _parser.parse;
            when 'nokogiri'
            _xml            = Nokogiri::XML.parse(response.body)
            when 'rexml'
            _xml            = REXML::Document.new(response.body);
          end
          nodes = _xpath.xpath_all(_xml, "//int");
          @ree  = nodes.length
          
          if field != "indice"
            nodes.each do |node|
              autocomplete_res << { :value => node["name"], :optional_value => ""};
            end
          else
            nodes.each do |node|
                p_data = PortfolioData.find_by_indice(node["name"])
                sup_value = ""
                if !p_data.blank?
                  sup_value = p_data.label_indice.strip
                  sup_value = sup_value[1..sup_value.length]
                end
                autocomplete_res << { :value => node["name"], :optional_value => sup_value};
            end
          end
      else
        logger.debug("ERROR Autocompleter Server not reachable");
      end
    end
    logger.debug("#STAT# [AUTOCOMPLETE] fin: " + sprintf( "%.2f",(Time.now().to_f - _sRTime)).to_s) if LOG_STATS;
    return autocomplete_res;
  end
  
  def SeeAlso(query)
    begin
      if SEE_ALSO_ACTIVATE == 1
        _a = SeeAlsoSearch.new()
        return _a.search_relations(query)
      else
        return []
      end
    rescue => e
      logger.error("[MetaSearch] SeeAlso: #{e.message}")
      return []
    end
  end
  
  # synopsis spellcheck (string query, hash hSetting)
  
  def spellCheck(query)
    if (SPELL_ACTIVATE != 1)
      return ([]);
    end
    arguments		= Hash.new();
    
    if (query.blank?)
      logger.debug("query is empty or nil");
      return ;
    end
    arguments["q"]                          = "aaaaaaaaaaaa";
    arguments["spellcheck.q"]               = query;
    arguments["spellcheck"]                 = true;
    arguments["spellcheck.extendedResults"] = true;
    arguments["spellcheck.count"]           = SPELL_COUNT;
    arguments["spellcheck.onlyMorePopular"] = true;
    arguments["spellcheck.collate"]         = true;
    conn                                    = Solr::Connection.new(Parameter.by_name('solr_requests'))
    
    begin
      request   = Solr::Request::SpellcheckCompRH.new(arguments);
      logger.debug("info request : " + request.handler);
      logger.debug("body request : " + request.to_s);
      logger.debug("request : " + request.inspect);
      response	= conn.send(request);
    rescue => e
      logger.debug("exception " + e.message);
    end
    if (response.nil?)
      return (nil);
    end
    return (response.get_response());
  end
  
  def GetMoreInfoForISBN(isbn, with_image = true)
    if ((isbn.nil?) || (isbn.blank?))
      return (nil);
    end 
    hResponse = Hash.new();
    _w  = ElectreWebservice.new(logger)
    logger.debug("[MetaSearch] : Electre connection")
    hResponse["back_cover"]        = _w.back_cover(isbn)
    hResponse["toc"] = _w.table_of_contents(isbn)
    if with_image
      hResponse["image"]            = _w.image(isbn);
    end
    logger.debug("[MetaSearch] [GetMoreInfoForISBN] : #{hResponse.inspect}")
    return (hResponse)
  end
  
  def GetEditorials(id)
    return Editorial.getEditorialsByGroupsId(id)
  end
  
  def GetPrimaryDocumentTypes
    return PrimaryDocumentType.find(:all)
  end
  
  def setInfosUser(infoUser)
		unless infoUser.nil?
			infoUser.location_user = 'EXTERNE' if infoUser.location_user.blank?
		end
    @infos_user = infoUser
    logger.debug("[MetaSearch][setInfosUser] Setting infos user : #{infoUser.inspect}")
    @log_management = LogManagement.instance
    @log_management.setInfosUser(@infos_user)
  end
  
end 
