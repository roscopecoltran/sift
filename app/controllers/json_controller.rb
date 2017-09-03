# -*- coding: utf-8 -*-
# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Solution & Innovation
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
# Atos Origin France - 
# Tour Manhattan - La Défense (92)
# roger.essoh@atosorigin.com
#
# http://libraryfind.org
#
# = Webservice for search in Libraryfind
# 
# * <tt>Search</tt> is the first method to call with parameters for search. This method return a array of jobs.
# * <tt>CheckJobStatus</tt> returns the states of jobs.
# * <tt>GetJobRecord</tt> must be called when all jobs are finished for retrieved all results.
# 
# This methods are accessible by this url: <tt>http ://<SERVEUR>/json/<METHOD></tt>
#
# == Variables in HTTP Header
# See JsonApplicationController and method analyse_request
#
# Parameters in <b>bold</b> are required, the <em>others</em> are optionals
#
#

class JsonController < JsonApplicationController

  include SearchHelper
  
  def initialize #:nodoc:
    super
  end
  def setInfosUser(infoUser)
     @info_user = infoUser
     @log_management = LogManagement.instance
     @log_management.setInfosUser(@info_user)
  end
  
  
  # == Create a search and save history_search
  # <em>ex:  search?query[string]='word'&sets=g42</em>
  #
  # Parameters:
  # * <b>query[string1]</b> : keyword for search. String.  
  # * <b>sets</b> : id group collection with prefix 'g'. String (ex: g1)
  # * <tt>query[max]</tt> : results max by collection. Integer
  # * <tt>query[string2]</tt> : keyword 2 for search. String
  # * <tt>query[string3]</tt> : keyword 3 for search. String
  # * <b>query[field_filter1]</b> : filter type. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[field_filter2]</tt> : filter type 2. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[field_filter3]</tt> : filter type 3. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>query[operator1]</tt> : operateur 1. String. ex: AND, OR, NOT
  # * <tt>query[operator2]</tt> : operateur 2. String. ex: AND, OR, NOT
  # * <tt>tab_template</tt> : tab template. String. ex: ALL, BOOK, etc..
  # * <tt>theme_id</tt> : id #search_tab_subject. Integer
  # * <tt>log_ctx</tt> : from research for statistics. String. ex: search, see_also
  # * with_facette is 0 1 or 2 for result only, (result+facet) and facet
  def Search
    error     = 0;
    _sTime    = Time.now().to_f
    id_search = -1
    begin
      #retrieve params
      init_search
      theme_id = extract_param("theme_id",  Integer, -1);
      log_cxt = extract_param("log_cxt",  String, nil);
      memcache = extract_param("memcache", String, nil);
      log_action = extract_param("log_action", String, "")
      tab_template = extract_param("tab_template", String, "")
      @query = @query.collect {|q| q.gsub('|', '&')}
      logger.debug("[JsonController - Search Params :]: #{@sets}, #{@type}, #{@query}, #{@start}, #{@max}, #{@operator}, #{@filter.inspect}, #{@sort_value}")
      
      _collection_group = CollectionGroup.get_item(@sets.slice(1,@sets.length-1))
      if (_collection_group.collection_type == DEFAULT_ASYNCHRONOUS_GROUP_COLLECTION or _collection_group.collection_type == ASYNCHRONOUS_GROUP_COLLECTION or _collection_group.collection_type == ALPHABETIC_GROUP_LISTE)
        is_asynchronous_collection = true
      else
        is_asynchronous_collection = false
      end
      if (is_asynchronous_collection)
        page_max = 0
        doc_inserts = Array.new
        
        if (@max.blank?)
          @max = 10
        end
        if (@start.blank?)
          @start = 1
        end
        if (!@filter.blank? and !@filter["vendor_name"].blank?)
          @filter["vendor_name"] = Collection.find_by_alt_name(@filter["vendor_name"]).name
        end

        options = {"sort" => @sort_value, "with_facette" => @with_facette, "tab" => tab_template}
          
        # si on veut les facettes uniquement pas besoin de demander des resultats
        if (options["with_facette"]=="2")
          @start = 1
          @max = 1
        end
           
        records, my_hits, total_hits, facette = $objDispatch.SolrSearch(@sets, @type, @query, @start, @max, @operator, @filter, options)
        
        # merge avec les notices pour le on cas
        #if (log_cxt =="get_notice" and records.length == 1)
        $objCommunityDispatch.mergeRecordWithNotices(records)
        #end
        if (log_cxt == "get_notice")
          to_log = {:log_cxt => "notice", :log_action => "consult" }
          $objDispatch.AddLogConsultSolr(to_log, records[0])
        end

        # pour la stats des notices recherches
        nb_doc = 0
        if  (!records.blank?)   
          records.each { |record|
            title = ""
            if (!record.title.blank?)
              title = record.title.strip
            elsif (!record.atitle.blank?)
              title = record.atitle.strip
            elsif (!record.ptitle.blank? )
              title = record.ptitle.strip
            end
            if (title != "")
              doc_statement = "('#{record.id}', '#{title.gsub(/[']/, '\\\\\'')}', '#{DateTime.now}')"
              doc_inserts.push(doc_statement)
              nb_doc+=1
              if (nb_doc > 10)
                break;
              end
            end
          }
          LogDoc.insert(doc_inserts)
        end
        
        # Calcul des pages
        page_max = (total_hits.to_f/@max.to_f).to_f.ceil
        searched_collections_results = Array.new 
        searched_collections = CollectionGroup.get_members_with_name(_collection_group.id)
        
        if (options["with_facette"]=="1" or options["with_facette"]=="2")
          # construction d'un hash sur facette
          databases_hash = Hash.new

          facette[:databases].each{|database|
            databases_hash[database.name] = database.value
          }
         
          #Calcul des collections recherches et rien
          collections_name_hash = Hash.new
          searched_collections.each{|col|
            # to give the real name to the facet
            collections_name_hash[col.name] = col.full_name 
            collection = Hash.new
            collection[:name] = col.full_name
            collection[:url] = col.url
            if databases_hash[col.name].blank?
              collection[:hits] = 0
            else
                collection[:hits] = databases_hash[col.name].to_i
            end
            searched_collections_results << collection
          }
          
          collection_full_name_hash = Hash.new
          searched_collections_results.each{|col|
            collection_full_name_hash[col[:name]]=col[:hits]
          }
          #todo logger here
          records.each {|rec|
             if !collection_full_name_hash[rec[:vendor_name]].blank?
               rec.hits = collection_full_name_hash[rec[:vendor_name]]
             else
               rec.hits = 0
             end 
          }
          # on renomme ensuite les facette avec le bon nom
          facette[:databases].each{|database|
            database.name = collections_name_hash[database.name]
          }
        else
          if (!facette[:databases].blank?)
            databases_hash = Hash.new
            facette[:databases].each{|database|
              databases_hash[database.name] = database.value
            }
            searched_collections.each{|col|
              collection = Hash.new
              collection[:name] = col.full_name
              collection[:url] = col.url
              if databases_hash[col.name].blank?
                  collection[:hits] = 0
              else
                  collection[:hits] = databases_hash[col.name].to_i
              end
              searched_collections_results << collection
            }
            collection_full_name_hash = Hash.new
            searched_collections_results.each{|col|
              collection_full_name_hash[col[:name]]=col[:hits]
            }
            records.each {|rec|
              if !collection_full_name_hash[rec[:vendor_name]].blank?
                 rec.hits = collection_full_name_hash[rec[:vendor_name]]
              else
                 rec.hits = 0
              end
            }
          end
        end
      else
        # we create thread of search
        ids = $objDispatch.SearchSync(@sets, @type, @query, @operator,nil,nil,nil,nil,nil,memcache) 
        
        # we have to wait for all the job to be complete
        job_completed = false
        cpt = 0
        while(job_completed==false and cpt < (2*SYNC_TIMEOUT))
          i = 0
          cpt = cpt + 1
          sleep(0.5)
          results = $objDispatch.CheckJobStatus(ids)
          results.each {|result|
            if (result.status  <= 0)
              i = i + 1
            end
          }
          
          if (i == ids.length)
            job_completed = true
          end
        end
        # killing all other thread that can always be running...
        $objDispatch.KillThread(ids, nil)

        #getting records
        records = $objDispatch.GetJobsRecords(ids);
				records.each do |r|
					r.availability = 'online' if ['Times Digital Archive', 'Contemporary Authors'].include? r.vendor_name
				end

        t = RecordController.new();
        t.setResults(records, @sort_value, @filter);    
        t.filter_results;
        facette = t.build_databases_subjects_authors();
        records = t.sort_results;

        if (log_cxt == "get_notice")
          to_log = {:log_cxt => "notice", :log_action => "consult" }
          $objDispatch.AddLogConsultSolr(to_log, records[@start.to_i - 1])
        end

        databases_hash = Hash.new
        facette[:databases].each{|database|
          databases_hash[database[0]] = database[1]
        }
                        
        #Calcul des collections recherches et rien
        searched_collections_results = Array.new 
        searched_collections = CollectionGroup.get_members_with_name(_collection_group.id)
        searched_collections.each{|col|
          collection = Hash.new
          collection[:name] = col.full_name
          collection[:url] = col.url
          if databases_hash[col.full_name].blank?
            collection[:hits] = 0
          else
            collection[:hits] = databases_hash[col.full_name].to_i
          end
          searched_collections_results << collection
        }

        # pagination des resultats
        page_list, results = lf_paginate(records, @start, @max)
        results.each{|_r|
          _r.hits = databases_hash[_r.vendor_name]
        }
        
        # merge avec les notices pour le on cas
        $objCommunityDispatch.mergeRecordWithNotices(results)

      end

      #if (!ids.nil?)
      search_input = ""
      search_group = ""
      search_type = ""
      tab_template = ""
      search_operator1 = ""
      search_type2 = ""
      search_input2 = ""       
      search_operator2 = ""
      search_type3 = ""
      search_input3 = ""
      
      cpt = 0
      @query.each do |v|
        if (cpt == 0)
          search_input = v
        elsif (cpt == 1)
          search_input2 = v
        elsif (cpt == 2)
          search_input3 = v
        end
        cpt += 1
      end
      
      cpt = 0
      @operator.each do |v|
        if (cpt == 0)
          search_operator1 = v
        elsif (cpt == 1)
          search_operator2 = v
        end
        cpt += 1
      end
      
      cpt = 0
      @type.each do |v|
        if (cpt == 0)
          search_type = v
        elsif (cpt == 1)
          search_type2 = v
        elsif (cpt == 2)
          search_type3 = v
        end
        cpt += 1
      end
      
      if (@with_facette == "0" or @with_facette == "1")
        if (!params["tab_template"].blank?)
          tab_template = params["tab_template"]
        end
        if (log_action != "nolog" and log_action != "facette")
          alpha = nil
          if (@filter and @filter.length > 0 and @filter["alpha"])
            alpha = @filter["alpha"]
          end
          if (is_asynchronous_collection)
            id_search = $objAccountDispatch.saveHistorySearch(tab_template, search_input, @sets, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, log_cxt, total_hits, log_action, alpha)
          else
            id_search = $objAccountDispatch.saveHistorySearch(tab_template, search_input, @sets, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, theme_id, log_cxt, records.length, log_action, alpha)
          end
        end
        if (log_action == "facette")
          begin
            $objAccountDispatch.addLogFacette(@filter);
          rescue => e
            logger.error("[JsonController][GetJobRecord] addLogFacette error : #{e.message}")
         end
        end
      end

    rescue => e
      error = -1;
      logger.error("[Json Controller][search] Error : " + e.message);
			#logger.error("[Json Controller][search] Error trace: " + e.backtrace.join('\n')); 
    end
    headers["Content-Type"] = "application/json; charset=utf-8"
    if (is_asynchronous_collection)
        # Dans le cas d'un recherche avec 0 resulat
        records = Array.new if records.blank?
        facette = Array.new if facette.blank?
        searched_collections_results = Array.new if searched_collections_results.blank?
        my_hits = 0 if my_hits.blank?
        total_hits = 0 if total_hits.blank?
      
        render :text => Yajl::Encoder.encode(
                   :results => {  :results => records, 
                                  :hits => my_hits, 
                                  :totalhits => total_hits, 
                                  :page => 1...(page_max+1).to_i,
                                  :facette=> facette,
                                  :history_id => id_search,
                                  :collection_group_members =>  searched_collections_results,
                                  :collections_group_sync => $objDispatch.ListGroupsSyn("", tab_template)},
                  :search_group => @sets,
                  :search_group_label => _collection_group.full_name,
                  :error => error)
     else
      render :text => Yajl::Encoder.encode({ 
          :results => { :results => results,
                        :facette    => facette,
                        :page       => page_list,
                        :totalhits => records.length ,
                        :collection_group_members => searched_collections_results,
                        :collections_group_sync => [],
                        :history_id => id_search,
                        :hits => results.length },
          :search_group => @sets, 
          :search_group_label => _collection_group.full_name,
          :error   => error
       }) 
    end
    
    logger.debug("#STAT# [JSON] search " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end 
  
  
  # == Add a log searches record to indicate a precalculated search has been queried.
  # <em>ex:  addHistoryReSearch?idgc=g597&type=keyword&query=monde78&filter=ALL</em>
  #
  # Parameters:
  # * <b>query</b> : keyword for search. String.  
  # * <b>idgc</b> : id group collection with prefix 'g'. String (ex: g1)
  # * <tt>input2</tt> : keyword 2 for search. String
  # * <tt>input3</tt> : keyword 3 for search. String
  # * <b>type</b> : filter type. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>type1</tt> : filter type 2. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>type2</tt> : filter type 3. #search_tab_filter. String. ex: keyword, subject, etc..
  # * <tt>operator1</tt> : operateur 1. String. ex: AND, OR, NOT
  # * <tt>operator2</tt> : operateur 2. String. ex: AND, OR, NOT
  # * <tt>tab_subject_id</tt> : ID of the tab_subject_id
  # * <tt>filter</tt> : filter on
  # @return {results => {history_id => integer}, error => error if error != 0, message => "error message"}
#  def addLogForSessionSearch
#    error     = 0;
#    _sTime    = Time.now().to_f
#    id_search = -1
#    begin
#      # Parametre obligatoire
#      search_input = extract_param("query",String,nil);
#      search_group = extract_param("idgc",String,nil);
#      search_type = extract_param("type",String,nil);
#      tab_template = extract_param("filter",String,nil);
#      tab_subject_id = extract_param("tab_subject_id",String,nil);
#      
#      # Parametre facultatif
#      search_operator1 = extract_param("operator1",String,nil);
#      search_type2 = extract_param("type2",String,nil);
#      search_input2 = extract_param("input2",String,nil);      
#      search_operator2 = extract_param("operator2",String,nil);
#      search_type3 = extract_param("type3",String,nil);
#      search_input3 = extract_param("input3",String,nil);
#      
#      logger.debug("[Json Controller][addHistoryReSearch] params : #{search_input}, #{search_group}, #{search_type}, #{tab_template}, #{tab_subject_id}")
#      
#      id_search = $objAccountDispatch.addHistoryReSearch(tab_template, search_input, search_group, search_type, search_operator1, search_input2, search_type2, search_operator2, search_input3, search_type3, tab_subject_id)
#
#    rescue => e
#      error = -1;
#      logger.error("[Json Controller][incrementRequestNumber] Error : " + e.message);
#    end
#      headers["Content-Type"] = "text/plain; charset=utf-8"
#      render :text => Yajl::Encoder.encode({ :results => {"history_id" => id_search },
#       :error   => error
#      })
#  end 
  
  # == Checks the status of research from jobs 
  # <em>ex:  CheckJobStatus?id[]=123&id[]=124</em>
  #
  # Parameters:
  # * <b>id[]</b> : array of jobs. [Integer].  
  # @return {results => array of #JobItem, error => error if error != 0, message => "error message"}
#  def CheckJobStatus
#    error = 0;
#    results = nil;
#    begin
#      if params[:id] != nil 
#        results = $objDispatch.CheckJobStatus(params[:id])
#      end
#    rescue => e
#      error = -1;
#      logger.error("[Json Controller][checkJobStatus] Error : " + e.message);
#    end
#    headers["Content-Type"] = "application/json; charset=utf-8"
#    render :text => Yajl::Encoder.encode({ :results => results,
#      :error   => error
#    })
#  end
  
  # == Get records by jobs id with pagination
  # <em>ex: GetJobRecord?id[]=12&id[]=122&page_size=10&page=1</em>
  #
  # Parameters:
  # * <b>id[]</b> : array of jobs. [Integer].  
  # * <b>page</b> : page number to return. Integer
  # * <tt>page_size</tt> : number of records to return. Integer (default (NB_RESULT_MAX))
  # * <b>notice_display</b> : get only one details record and some information for pagination. Integer (O or 1)
  # * <b>group</b> : id group collection with prefix 'g'. String (ex: g1)
  # * <b>sort_value</b> : sorting criteria.[relevance, dateup, datedown, authorup, authordown, titleup, titlefdown, harvesting_date]. String ex: 'relevance'
  # * <tt>filter</tt> : filters. name of facette and value. String. ex: "author#Name/material_type#Base"
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # * <tt>filter</tt> : filters. name of facette and value. String. ex: "author#Name/material_type#Base"
  # * <tt>with_facette</tt> : get facets. Integer (0 or 1) 
  # * <tt>stop_search</tt> : kill all jobs not finished. Integer (0 or 1) 
  # * <tt>temps</tt> : get records before this time. String. timestamp
  # * <tt>with_total_hits</tt> : return last result of #CheckJobStatus method. Integer (0 or 1)
  #
  # === If notice_display == 0
  # @return {:results => {:results => #Record array, :facette => array facetes, :page => page list, total_hits => Array of #JobItem, hits => Integer}, error => error if error != 0, message => "error message"}
  # 
  # === If notice_display == 1
  # @return {:results => {:current => #Record,:next => has a next record Integer (0 or 1), :previous => has a previous record Integer (0 or 1), :facette => array facetes, :total_hits => Array of JobItem, hits => Integer}, error => error if error != 0, message => "error message"}
#  def GetJobRecord
#    error   = 0;
#    final_hits = 0
#    message = ""
#    _sTime = Time.now().to_f
#    headers["Content-Type"] = "application/json; charset=utf-8"
#    begin
#      log_action = extract_param("log_action",String,"");
#      log_cxt = extract_param("log_cxt",String,"");
#      
#      t = RecordController.new();
#      
#      # get jobs id
#      id = params[:id].blank? ? raise("id is null please fill it") : params[:id];
#      
#      # get max records by database
#      max = params[:max].blank? ? getMaxCollectionSearch() : params[:max];
#      
#      # get booleans value
#      with_total_hits = (params[:with_total_hits].blank? or (!params[:with_total_hits].blank? and params[:with_total_hits] == '1'))
#      with_facette = true
#      if (!params[:with_facette].blank? and params[:with_facette] == '0')
#        with_facette = false
#      end
#      
#      # get results by pages
#      @page_size  = NB_RESULTAT_MAX
#      if (!params[:page_size].blank?) 
#        begin
#          @page_size = Integer(params[:page_size]);
#          if @page_size <= 0
#            @page_size  = NB_RESULTAT_MAX
#          end
#        rescue => e
#          logger.warn("[JsonController][GetJobRecord] for page_size => #{e.message} #{e.backtrace.join('\n')}")
#        end
#      end
#      
#      # get id collection_group
#      group  = -1
#      if (!params[:group].blank?) 
#        begin
#          group = params[:group].slice(1,params[:group].length-1)
#          group = Integer(group)
#          collection_group = CollectionGroup.find(:first, :conditions => {:id => [group]})
#        rescue => e
#          group = -1
#          message = e.message
#          logger.warn("[JsonController][GetJobRecord] for group => #{e.message}")
#        end
#      end
#      
#      # get sort value
#      @sort_value = params[:sort].blank? ? 'relevance': params[:sort]
#      
#      # get filter values
#      @filter = params[:filter].blank? ? nil : params[:filter].collect! {|items| items.split('#')}
#      logger.debug("[JsonController][GetJobRecord] params: #{id.inspect} max: #{max} group: #{group} sort:#{@sort_value} filter:#{@filter.inspect} page_size:#{@page_size}") 
#      logger.debug("[JsonController][GetJobRecord] options: with_total_hits: #{with_total_hits} with_facette:#{with_facette}")
#      logger.debug("#STAT# [JSON] GetJobRecord 1 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#      
#      if (log_action == "facette")
#        begin
#          $objAccountDispatch.addLogFacette(@filter);
#        rescue => e
#          logger.error("[JsonController][GetJobRecord] addLogFacette error : #{e.message}")
#        end
#      end
#      # stop search
#      stop_search = extract_param("stop_search",Integer,0)
#      if (stop_search == 1) 
#        for job in id
#          item=$objDispatch.CheckJobStatus(job)
#          if item.status==JOB_WAITING
#            if item.thread_id.to_i>0
#              begin
#                logger.debug("[JsonController][GetJobRecord] KillThread for job: #{job}")
#                $objDispatch.KillThread(job, item.thread_id)
#              rescue Exception => e
#                logger.error("[JsonController][GetJobRecord] error : #{e.message}")
#              end
#            end
#          end
#        end
#      end
#      sjobs_ids = ""
#      id.each do |job_ids|
#        if sjobs_ids == ""
#          sjobs_ids = job_ids.to_s
#        else
#          sjobs_ids = sjobs_ids + "_" + job_ids.to_s
#        end
#      end
#      hist_id = HistorySearch.getHistoryIdByjobsId(sjobs_ids)
#      temps = extract_param("temps",String,nil);
#      
#      # get results
#      logger.debug("[JsonController][GetJobRecord] search results for jobs: #{id} and max:#{max}")
#      @results    = $objDispatch.GetJobsRecords(id, max, temps);
#      logger.debug("[JsonController][GetJobRecord] after getJobsRecords size of Result : " + @results.length.to_s);
#      logger.debug("#STAT# [JSON] GetJobRecord 2 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#      
#      logger.debug("[JsonController][GetJobRecord] filter : #{@filter.inspect}") 
#      
#      # set params to recordController
#      t.setResults(@results, @sort_value, @filter);
#      # call filter results      
#      t.filter_results;
#      # get results to sort
#      @results = t.sort_results;
#      # set hits after filter
#      hits = 0
#      if !@results.nil?
#        hits = @results.size
#        final_hits = final_hits + hits
#      end
#      
#      if final_hits == 0 and stop_search == 1
#        $objDispatch.addLogSearchUpdate(hist_id, final_hits, log_cxt)
#      end
#      logger.debug("[JsonController][GetJobRecord] after sort size of Result : " + @results.length.to_s);
#      logger.debug("#STAT# [JSON] GetJobRecord 3 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#      
#      # get total_hits
#      @total_hits = nil
#      if with_total_hits
#        @totalhits = $objDispatch.GetTotalHitsByJobs(id);
#      end
#      logger.debug("#STAT# [JSON] GetJobRecord 4 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#      # generate page_list
#      if (@performance)
#        lf_paginate(@totalhits[0][:total_hits]);
#      else
#        lf_paginate(@results.length);
#      end
#      
#      # construct facette
#      facette = nil
#      if with_facette
#        facette = t.build_databases_subjects_authors();
#      end
#      logger.debug("#STAT# [JSON] GetJobRecord 5 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#      
#      notice_display = params[:notice_display].blank? ? "0": params[:notice_display];
#      
#      if (notice_display == "1")
#        if @results_page.nil? or @results_page.empty?
#          raise "error"
#        end
#        
#        log_action = "consult";
#        log_cxt = "notice"
#        current,error = GetIdGeneric(@results_page[0].id, log_action, log_cxt);
#        
#        render :text => Yajl::Encoder.encode({:results  => {
#            :current  => current,
#            :next     => @show_next,
#            :previous => @show_previous,
#            :facette  => facette,
#            :page     => nil,
#            :totalhits  => @totalhits,
#            :hits => hits
#          },
#          :error    => error, 
#          :message => message
#        })
#        logger.debug("#STAT# [JSON] GetJobRecord by notice " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#        return ;
#      else
#        # tab id
#        # merge record with notice
#        logger.debug("[JsonController][GetJobRecord] @results_page : #{@results}") 
#        @results_page = $objCommunityDispatch.mergeRecordWithNotices(@results_page) 
#        logger.debug("[JsonController][GetJobRecord] @results_page after : #{@results_page}") 
#      end
#    rescue => e
#      error = -1;
#      message = e.message
#      logger.error("[Json Controller][GetJobRecord] Error : " + e.message);
#      logger.error("[Json Controller][GetJobRecord] " + e.backtrace.join("\n"))
#    end 
#    logger.debug("#STAT# [JSON] GetJobRecord 6 " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#    
#    render  :text => Yajl::Encoder.encode({ :results    => { :results => @results_page,
#        :facette    => facette,
#        :page       => @page_list,
#        :totalhits => @totalhits,
#        :hits => hits
#      },
#      :error      => error,
#      :performance => 0,
#      :message      => message
#    })
#    logger.debug("#STAT# [JSON] GetJobRecord " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
#    return ;
#  end	
  
  # == List all collections
  #
  # @return {results => Array of #Collection, :error => code error}
  def ListCollections
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.ListCollections
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListCollection] Error : " + e.message);
    end
    headers["Content-Type"] = "application/json; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end

	def searchAuthorities
		error = 0
		q = params[:q]
		direction = params[:direction].nil? ? :descending : params[:direction].to_sym
		size = params[:size].nil? ? 10 : params[:size]
		begin
			conn = Solr::Connection.new(Parameter.by_name('authorities_solr'))
			fields = ['seq_no', 'relation', 'rejete', 'retenu']
			query = "seq_no:(#{q}) OR retenu:(#{q})^20 OR rejete:(#{q})^10 OR relation:(#{q})"
			opt = {:sort => [{ 'score' => direction}], :rows => size}
			response = conn.query(query, opt)
		rescue => e
			error = -1
			logger.error("[JsonController][searchAuthorities] Error: #{e.message}")
		end
		headers["Content-Type"] = "application/json; charset=utf-8"
		render :text => Yajl::Encoder.encode({:response => response, :error => error })
	end

	def searchWithPerma
		error = 0
		q = params[:q]
		begin
			p = PortfolioData.find(:first, :conditions => "dc_identifier = #{q}")
			m = Metadata.find(p.metadata_id)
			type = PrimaryDocumentType.find(:first, :conditions => "name = '#{m.dc_type}'")
			type = type.nil? ? 1 : type.id
			image_url = "http://10.1.2.119/tout/document/getImage?isbn=#{p.isbn}&material_type=#{m.dc_type}&which_icon=no_image_icon"
			response = { :title => m.dc_title, :link => "permalien/document?doc=#{q}%3B5%3B0", :author => m.dc_creator, :editor => m.dc_publisher, :date => m.dc_date, :indice => p.indice + ' ' + p.label_indice, :format => m.dc_format, :country => p.publisher_country, :description => m.dc_description + ' ' + p.abstract, :support => type, :image => image_url, :alt => m.dc_title, :id => q, :theme => p.theme }
		rescue => e
			error = -1
			logger.error("[JsonController][searchAuthorities] Error: #{e.message}")
		end
		headers["Content-Type"] = "application/json; charset=utf-8"
		render :text => Yajl::Encoder.encode({:response => response, :error => error })
	end
  
  # List all collection group asyn
  def ListGroupsSyn
    error   = 0;
    results = nil;
    begin
      id_CG = extract_param("id_CG", Integer, nil);
      tab_name = extract_param("tab_name", String, "");
      results = $objDispatch.ListGroupsSyn(id_CG, tab_name)
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListCollection] Error : " + e.message);
    end
    headers["Content-Type"] = "application/json; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == List group of collection
  #
  # Parameter
  # * <tt>advanced</tt> : only group for advanced search. Integer (O or 1)   
  # @return {results => Array of #Collection, error => code error }
  def ListGroups
    error   = 0;
    results = nil;
    begin
      bool_advanced = !params[:advanced].blank? && params[:advanced] == "1" 
      results = $objDispatch.ListGroups(bool_advanced)
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListGroups] Error : " + e.message);
    end
    headers["Content-Type"] = "application/json; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == ListAlpha is  in an id of an alphebetic group of collection
  #
  # Parameter
  # * <b>tab_id</b> : the id of the tab. String   
  # @return {results => the id of collection group, error => code error }
  def ListAlpha
    error   = 0;
    results = nil
    begin
      tab_id = params[:tab_id]
      results = $objDispatch.ListAlpha(tab_id)
    rescue => e
      error = -1;
      logger.error("[Json Controller][ListAlpha] Error : " + e.message);
    end
    headers["Content-Type"] = "application/json; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get collections in a group of collection
  #
  # Parameter
  # * <b>name</b> : name of group collection. String   
  # @return {results => Array of #Collection, error => code error }
  def GetGroupMembers
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetGroupMembers(params[:name])
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetGroupMembers] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8"
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get tabs
  #
  # @return {results => Array of #SearchTab, error => code error }
  def GetTabs
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetTabs;
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetTabs] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get filters for all tabs
  #
  # @return {results => Array of #SearchTabFilter, error => code error }
  def GetFilter
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.GetFilter;
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetFilter] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Kill a job
  # 
  # This method can be called in order to stop one job in a research.
  # The parameter "threadid" is returned in a JobItem
  # Parameters
  # * <b>jobid</b> : job id. Integer 
  # * <b>threadid</b> : process id. Integer 
  #
  # @return {error => code error }
#  def KillThread
#    error = 0;
#    begin
#      jobid = params[:jobid]
#      threadid = params[:threadid]
#      result = $objDispatch.KillThread(jobid, threadid)
#    rescue => e
#      error = -1;
#      logger.error("[Json Controller][KillThread] Error : " + e.message);
#    end
#    
#    headers["Content-Type"] = "text/plain; charset=utf-8"
#    render :text => Yajl::Encoder.encode({:result  => result, :error => error})
#  end
  
  # == Get Top ten of records viewed
  # 
  # This method is based on the statistics
  #
  # @return {results => Array of #Record, error => code error }
  def TopTenMostViewed()
    error   = 0;
    results = nil;
    begin
      results = $objDispatch.topTenMostViewed();
    rescue => e
      error = -1;
      logger.error("[Json Controller][TopTenMostViewed] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Get all themes for tabs
  # 
  # You can specify a tab name. #SearchTab
  #
  # Parameter
  # * <tt>theme</theme> : id of #SearchTab
  # @return {results => Array of #SearchTabSubjects, error => code error }
  def GetTheme()
    error   = 0;
    results = nil;
    begin
      theme = params[:theme].blank? ? nil : params[:theme];
      results = $objDispatch.getTheme(theme);
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetTheme] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == Obtain a detailed record with its id
  # 
  # The parameter idSearch is only required for a record retourned by a synchronous connector (ex: Z39.50, SRU etc..)
  #
  # Parameter
  # * <b>idDoc</b> : id of record. String
  # * <b>idCollection</b> : id of #Collection. Integer
  # * <em>idSearch</em> : id of #CachedSearch. Integer.
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # @return {results => #Record, error => code error, message => error message}
  def GetId()
    _sTime = Time.now().to_f
    error   = 0;
    results = nil;
    message = ""
    begin
      log_action = extract_param("log_action",String,"");
      log_cxt = extract_param("log_cxt",String,"");
      
      if ((!params[:idDoc].blank?) && (!params[:idCollection].blank?))
        idDoc     = params[:idDoc];
        idCol     = params[:idCollection];
        idSearch  = params[:idSearch];
        
        if (idSearch.blank?)
          idSearch = 0;
        end
        results, error = GetIdGeneric("#{idDoc};#{idCol};#{idSearch}", log_action, log_cxt);
      else
        error = 102;
      end
    rescue => e
      error = -1;
      message = e.message
      logger.error("[Json Controller][GetId] Error : " + e.message);
      logger.error("[Json Controller][GetId] #{e.backtrace}")
    end
    headers["Content-Type"] = "application/json; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error,
      :message    => message
    })
    
    logger.debug("#STAT# [JSON] GetId " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == Autocomplete 
  # 
  # This method return a list of words from characters
  #
  # Parameter
  # * <b>word</b> : id of record. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def AutoComplete
    error   = 0;
    results = nil;
    begin
      word = nil;
      field = nil;
      
      if (!params[:word].blank?)
        word  = params[:word];
      end
      if (!params[:field].blank?)
        field  = params[:field];
      end
      results = $objDispatch.autoComplete(word, field);
    rescue => e
      error = -1;
      logger.error("[Json Controller][AutoComplete] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == SpellCheck 
  # 
  # This method is as a spell checker and returns a list of words from a word
  #
  # Parameters
  # * <b>word</b> : word. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def SpellCheck
    error   = 0;
    results = nil;
    begin
      query = String.new();
      if (!params[:query].blank?)
        query   = params[:query];
      end
      results   = $objDispatch.spellCheck(query);
    rescue => e
      error = -1;
      logger.error("[Json Controller][SpellCheck] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == SeeAlso 
  # 
  # This method returns a list of words from a word.
  # It's a list of synonyms
  #
  # Parameter
  # * <b>query</b> : word. String
  # * <em>field</em> : name of index (#SearchTabFilter.field_filter). String. ex: keyword
  #
  # @return {results => array of words, error => code error, message => error message}
  def SeeAlso
    error   = 0;
    results = nil;
    begin
      logger.debug("[SeeAlso] params: #{params.inspect}")
      _q = params[:query]
      results = $objDispatch.SeeAlso(_q);
    rescue => e
      error = -1
      logger.error("[Json Controller][SeeAlso] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
  end
  
  # == GetMoreInfoForISBN 
  # 
  # This method use ElectreWebService for return an abstract and a table of content from a isbn number
  #
  # Parameter
  # * <b>id</b> : isbn. String
  #
  # @return {results => {:quatrieme => abstract String, tableDesMatiers => summary }, error => code error, message => error message}
  def GetMoreInfoForISBN()
    _sTime = Time.now().to_f
    error   = 0;
    results = nil;
    begin
      isbn = params[:id];
      logger.debug("[Json Controller][getMoreInfo] ISBN : " + isbn.to_s);
      results = $objDispatch.GetMoreInfoForISBN(isbn, false);
    rescue => e
      error = -1;
      logger.error("[Json Controller][getMoreInfo] Error : " + e.message);
      logger.error("[Json Controller][getMoreInfo] Error : " + e.backtrace.join("\n"));
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => { 
        :quatrieme => results["back_cover"] , 
        :tableDesMatieres => results["toc"] },
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetMoreInfoForISBN " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  # == GetIds 
  # 
  # Return an array of records by an array of identifiers
  #
  # Parameters
  # * <b>ids</b> : array of Idenfifier. String. ex: [1212332;12;1212] idRecord;idCollection[;IdSearch]
  # * <tt>log_ctx</tt> : context of this call for statistics. String. ex: search, notice, account, basket
  # * <tt>log_action</tt> : cause of this call for statistics. String (ex: consult, rebonce, pdf, email, print )
  # @return {results => Array of #Record, error => code error}
  def GetIds
    error   = 0;
    results = Array.new();
    _sTime = Time.now().to_f
    begin
      
      log_action = extract_param("log_action",String,"");
      log_cxt = extract_param("log_cxt",String,"");
      
      if (!params[:ids].blank?)
        notices = params[:ids]
        
        notices.each do |notice|
          res, err = GetIdGeneric(notice, log_action, log_cxt);
          if (!res.nil?)
            results.push({:results => res, :error => err});
          end
        end
      end
    rescue => e
      logger.error("[Json Controller][GetIds] Error : " + e.message + e.backtrace.join("\n"));
      error = -1;
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({   
      :results  => results,
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetIds " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    
  end
  
    # == getCollectionAuthenticationInfo 
  # 
  # Return an array of records by an array of identifiers
  #
  # Parameters
  # 
  # @return {results => Array of #Record, error => code error}
  def getCollectionAuthenticationInfo
    error   = 0;
    collection_id = ""
    if (!params[:collection_id].blank?)
        collection_id = params[:collection_id]
    end
    results = nil;
    begin
      results = $objDispatch.getCollectionAuthenticationInfo(collection_id);
    rescue => e
      error = -1;
      logger.error("[Json Controller][getCollectionAuthenticationInfo] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
    
  end
  
  # == GetPrimaryDocumentTypes 
  # 
  # Return an array of #PrimaryDocumentType 
  # PrimaryDocumentType are used in the material_type property of records
  #
  # @return {results => Array of #PrimaryDocumentType, error => code error}
  def GetPrimaryDocumentTypes
    error   = 0
    results = nil
    _sTime = Time.now().to_f
    begin
      results = $objDispatch.GetPrimaryDocumentTypes
    rescue => e
      error = -1;
      logger.error("[Json Controller][GetPrimaryDocumentTypes] Error : " + e.message);
    end
    headers["Content-Type"] = "text/plain; charset=utf-8";
    render :text => Yajl::Encoder.encode({ :results  => results,
      :error    => error
    })
    logger.debug("#STAT# [JSON] GetPrimaryDocumentTypes " + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
  end
  
  private
  
  def GetIdGeneric(id, log_action, log_cxt) #:nodoc:
    _sTime = Time.now().to_f
    results = nil
    error   = 0
    results = $objDispatch.GetId(id, {:log_action => log_action, :log_cxt => log_cxt});
    logger.debug("#STAT# [JSON] GetIdGeneric (1)" + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    if (results.nil?)
      error = 103;
      r = Record.new();
      r.id = id;
      tab = $objCommunityDispatch.mergeRecordWithNotices([r])
    else
      tab = $objCommunityDispatch.mergeRecordWithNotices([results])
    end
    logger.debug("#STAT# [JSON] GetIdGeneric (2)" + sprintf( "%.2f",(Time.now().to_f - _sTime)).to_s) if LOG_STATS
    if (tab.empty?)
      return ([nil, 104])
    end
    results = tab[0];
    return ([results, error]);
  end
end
