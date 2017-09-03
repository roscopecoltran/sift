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

class RssController < ApplicationController
  include SearchHelper
  include ApplicationHelper
  
  # params required :
  #   query[string] = words search ex: word
  #   query[type] = field filter ex:keyword 
  #   query[max] = max results
  #   sets = collections group
  #   filter = filter facette ex:autor
  #   sort_value = sort ex:relevande
  def search
    begin
      logger.info("[RssController] search : #{params.inspect}")
      init_search
      # stats
      items = {:rss_url => "#{params.inspect}", :host => "#{request.remote_addr}"};
      LogGeneric.addToFile("LogRssUsage", items)
        
      logger.debug("[RSS_Controller] params : #{@sets}, #{@type}, #{@query}, #{@start}, #{@max}, #{@operator}, #{@filter.inspect}, #{@sort_value}")
    
      _collection_group = CollectionGroup.get_item(@sets.slice(1,@sets.length-1))
      if (_collection_group.collection_type == DEFAULT_ASYNCHRONOUS_GROUP_COLLECTION or _collection_group.collection_type == ASYNCHRONOUS_GROUP_COLLECTION )
        is_asynchronous_collection = true
      else
        is_asynchronous_collection = false
      end
      
      @max = MAX_RSS_NOTICE
      @start = 1  
        
      if (is_asynchronous_collection)
        options = {"isbn" => 0, "news" => 0, "query" => "", "sort" => "DATE-DESC", "with_facette" => "0"}
        @records, my_hits, total_hits, facette = $objDispatch.SolrSearch(@sets, @type, @query, @start, @max, @operator, @filter, options)
      else
        # we create thread of search
        ids = $objDispatch.SearchSync(@sets, @type, @query, @start, @max, @operator) 
        
        # we have to wait for all the job to be complete
        job_completed = false
        cpt = 0
        while(job_completed==false and cpt < (2*RSS_TIMEOUT))
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
        @records = $objDispatch.GetJobsRecords(ids);
        
        t = RecordController.new();
        t.setResults(@records, @sort_value, @filter);    
        t.filter_results;
        facette = t.build_databases_subjects_authors();
        @records = t.sort_results;
       
        databases_hash = Hash.new
        facette[:databases].each{|database|
          databases_hash[database[0]] = database[1]
        }
        
        # pagination des resultats
        page_list, @records = lf_paginate(@records, @start, @max)
        @records.each{|_r|
          _r.hits = databases_hash[_r.vendor_name]
        }
        
        if @records.nil?  
          @records = Array.new
        end
      end
    rescue => e
      error = -1;
      logger.error("[Json Controller][search] Error : " + e.message);
      logger.error("[Json Controller][search] Error : #{e.backtrace}" );
    end
    
    headers["Content-Type"] = "application/xml"
    render :layout =>false
  end
  
  def feed
    begin
      logger.info("[RssController] feed : #{params[:query][:rss_id]}")
      @title = ""
      
      rss_feed = RssFeed.find(:first, :conditions => " id = #{params[:query][:rss_id].to_i}")
      if(!rss_feed.nil?)
        
        @title = rss_feed.full_name
        params[:sets] = "g"+rss_feed.collection_group.to_s
                
        params[:query][:string] = "";
        params[:query][:type] = "";
        
        logger.info("[RssController] rss_feed.primary_document_type : #{rss_feed.primary_document_type}")
        options = {}
          
        if rss_feed.primary_document_type != 1 # correspond à NONE
          pdt = PrimaryDocumentType.find(:first, :conditions =>"id = #{rss_feed.primary_document_type}")
          params[:query][:string] = pdt.name
          params[:query][:type] = "document_type"
          options["news_period"] = pdt.new_period
        end
     
        options["isbn"] = rss_feed.isbn_issn_nullable        
        options["news"] = rss_feed.new_docs
        options["query"] = rss_feed.solr_request
        options["sort"] = "DATE-DESC"
        options["with_facette"] = "0"
        
        init_search
            
        _collection_group = CollectionGroup.get_item(rss_feed.collection_group.to_s)
        if (_collection_group.collection_type == DEFAULT_ASYNCHRONOUS_GROUP_COLLECTION or _collection_group.collection_type == ASYNCHRONOUS_GROUP_COLLECTION )
          is_asynchronous_collection = true
        else
          is_asynchronous_collection = false
        end
        
        @max = MAX_RSS_NOTICE
        @start = 1  
        if (is_asynchronous_collection)
          @records, my_hits, total_hits, facette = $objDispatch.SolrSearch(@sets, @type, @query, @start, @max, @operator, @filter, options)
        end
      end
    rescue => e
      logger.error("[RssController] error : #{e.message}")
      logger.error("[RssController] error : #{e.backtrace.join("\n")}")
    end
    
    headers["Content-Type"] = "application/xml"
    render :layout =>false
    
  end

end
