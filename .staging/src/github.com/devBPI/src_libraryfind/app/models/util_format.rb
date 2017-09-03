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

require 'collection'
require 'htmlentities'

class UtilFormat
    
  yp = YAML::load_file(RAILS_ROOT + "/config/ranking.yml")
  TITLE_PERFECT_MATCH = yp['TITLE_SOLR_MATCH']
  CREATOR_PERFECT_MATCH = yp['CREATOR_SOLR_MATCH']
  SUBJECT_PERFECT_MATCH = yp['SUBJECT_SOLR_MATCH']
  THEME_PERFECT_MATCH = yp['THEME_SOLR_MATCH']
  TITLE_PERFECT_MATCH_EXACT = yp['TITLE_SOLR_MATCH_EXACT']
  CREATOR_PERFECT_MATCH_EXACT = yp['CREATOR_SOLR_MATCH_EXACT']
  SUBJECT_PERFECT_MATCH_EXACT = yp['SUBJECT_SOLR_MATCH_EXACT']
  THEME_PERFECT_MATCH_EXACT = yp['THEME_SOLR_MATCH_EXACT']
  INDICE_PERFECT_MATCH = yp['INDICE_SOLR_MATCH']
  DATE_BOOST = yp['DATE_BOOST']

  def self.generateRequestSolr(_qtype, _qstring, _qoperator, filter_query, isParent, collection_id, collection_name, max, options, _qsynonym=nil)
     
     params = UtilFormat.generateQuerySolr(_qtype, _qstring, _qoperator, _qsynonym)
     raw_query_string = ""
     if isParent == 1
       raw_query_string = "+collection_id:(\"#{collection_id}\")"
     elsif !collection_name.blank?
       collection_name = collection_name.gsub("http_//", "")
       raw_query_string = "+collection_name:(\"#{collection_name}\")"
     end
     
     #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr1] => #{raw_query_string}")
     if !params.blank? and !params.eql?("( )")
       raw_query_string += " #{params}"
     end
     
     if filter_query.blank?
       filter_query = ""
     end
     
     #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr] filter_query => #{filter_query}")
     raw_query_string += "#{filter_query}"
     #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr2] => #{raw_query_string}")
     
     # Adding options
     if !options.nil?
       if !options["isbn"].nil? and options["isbn"].to_i == 1
         raw_query_string += " isbn:[* TO *] "
       end
       if !options["news"].nil? and options["news"].to_i == 1
         raw_query_string += " harvesting_date:[NOW-#{options["news_period"]}DAY TO NOW]"
       end
       if !options["query"].nil? and !options["query"].blank?
         raw_query_string += " +#{options["query"].strip} "          
       end
     end
     
     opt = {}
     opt[:rows] = max
       
     if (!options.nil? and !options["sort"].blank?)
       case(options["sort"])
         when "DATE-ASC" # Par date montante
           opt[:sort] = [{"harvesting_date" => "ascending"}]
           # We need to inform the search class that we should not select the item by solr but just by the dc_date
           # opt[:sort_filter] = "no_selection"
         when "DATE-DESC"
           opt[:sort] = [{"harvesting_date" => :descending}]
           # We need to inform the search class that we should not select the item by solr but just by the dc_date
           #opt[:sort_filter] = "no_selection"
         else
           # In case we want to sort by another field ascending
           opt[:sort] = [{options["sort"] => "ascending"}]
         end
      end
     ActiveRecord::Base.logger.info("[UtilFormat] [generateRequestSolr] => #{raw_query_string} opt: #{opt.inspect}")
     return raw_query_string, opt
   end
   
 	def self.generateMultipleRequestSolr(_collections, _qtype, _qstring, _qoperator, start, max, options, _qsynonym=nil, _filter=nil, infos_user = nil)
     raw_query_string = "("
     # On parcours toutes les collections
     _collections.each { |collection|
       raw_query_string +="(collection_id:(\"#{collection.id}\")"
       if !collection.filter_query.blank?
         raw_query_string += " AND (#{collection.filter_query})"
       end
       raw_query_string +=") OR "
     }
     raw_query_string = raw_query_string.slice(0, (raw_query_string.length - 4)) + ")"
		 
     #ActiveRecord::Base.logger.debug("[UtilFormat] [generateRequestSolr1] => #{raw_query_string}")
     params = UtilFormat.generateQuerySolr(_qtype, _qstring, _qoperator, _qsynonym, options)
     if !params.blank? and !params.eql?("((()))")
       raw_query_string += " AND #{params}"
     end
         
     opt = {}
     opt[:field_list] = ["id","harvesting_date","theme","date_end_new"]
     opt[:rows] = max
     if (opt[:rows] <= 0)
        opt[:rows] = 25
     end
     if (opt[:rows] >= 200)
       opt[:rows] = 200
     end
     opt[:start] = (start-1) * max
     if (opt[:start] <= 0)
      opt[:start] = 0
     end
     
    filter_query = UtilFormat.generateFilterQuerySolr(_qtype, _qstring, _qoperator, _qsynonym, options)
    _fq = UtilFormat.generateFilter(_filter, infos_user,_collections)
    if filter_query.blank?   
      filter_query +=_fq
    elsif !_fq.blank?
      filter_query +=" AND " + _fq
    end
    opt[:filter_queries] = filter_query
       
    if (options["with_facette"]=="1" or options["with_facette"]=="2") 
       time = Time.now
       disponibilite_facet_query = UtilFormat.generateAvailabilityFacet(infos_user, _collections)
       opt[:facets] = { 
            :mincount => 1, :limit => 1000, :sort=> "count", 
            :queries => disponibilite_facet_query,
            :fields => [  "theme_exact",
													"musical_kind_exact",
                          "document_type_exact", 
                          "author_exact",
                          "lang_exact",
                          "subject_exact",
                          "collection_name_exact"],
            :dates => [  "date_document" => 
                        {   :start => "1800-01-01T00:00:00Z", 
                            :end => "#{time.year}-12-31T23:59:59Z", 
                            :gap =>"+1YEAR",
														:other => "before",
                            :include => "lower"} ] }
 	  else
        opt[:facets] = { 
            :mincount => 1, :limit => 1000, :sort=> "count", 
            :fields => ["collection_name_exact" ] }             
    end

    if (!options.nil? and !options["sort"].blank?)
      case(options["sort"])
        when "DATE-ASC" # Par date montante
          opt[:sort] = [{"harvesting_date" => :ascending}]
        when "DATE-DESC"
          opt[:sort] = [{"harvesting_date" => :descending}]
        when "relevance"
          opt[:sort] = [{"score" => :descending}]
        when "authorup"
         opt[:sort] = [{"author_sort" => :ascending}]
        when "authordown"
         opt[:sort] = [{"author_sort" => :descending}]
        when "dateup"
         opt[:sort] = [{"date_document" => :ascending}]
        when "datedown"
         opt[:sort] = [{"date_document" => :descending}]
        when "titleup"
         opt[:sort] = [{"title_sort" => :ascending}]
        when "titledown"
         opt[:sort] = [{"title_sort" => :descending}]
      end
    end
    ActiveRecord::Base.logger.info("[UtilFormat] [generateRequestSolr] => #{raw_query_string} opt: #{opt.inspect}")
    return raw_query_string, opt, disponibilite_facet_query
  end
  
  def self.generateFilterQuerySolr(_qtype, _qstring, _qoperator, _qsynonym = nil, options= nil)
   if _qtype.length < _qstring.length
     ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] qstring and qtype not the same lengths")
     return nil
   end
   if _qoperator.length < _qtype.length-1
     ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] ERROR - qstring miss or too much elements")
     return nil
   end 
   if _qtype.blank?
     return nil
   end
   
   i = 0
   query = "(("
   while i < _qtype.length do
     query += generateSynonym(_qtype, _qstring, _qsynonym, i)
     if i == 1
       query += ")"
     end
     if i < _qoperator.length && _qtype.length > _qoperator.length
       query += " " + _qoperator[i] + " "
     end
     i += 1
   end
   if i  == 1 
     query += ")"
   end
   query += ")"
   
   # If we want to log the whole query
   ActiveRecord::Base.logger.debug("[UtilFormat][generateQuerySolr] generated query : #{query}")
   if query!="(())"
     return query
   else
     return ""
   end
  end
  
  def self.generateQuerySolr(_qtype, _qstring, _qoperator, _qsynonym = nil, options= nil)
   
   if _qtype.length < _qstring.length
     ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] qstring and qtype not the same lengths")
     return nil
   end
   if _qoperator.length < _qtype.length-1
     ActiveRecord::Base.logger.error("[UtilFormat][MultifieldOrganize] ERROR - qstring miss or too much elements")
     return nil
   end 
   if _qtype.blank?
     return nil
   end
   
   i = 0
   query = "(("
   while i < _qtype.length do
     query += "("
     query += generateSynonym(_qtype, _qstring, _qsynonym, i)
     if (!options.nil? and options["sort"]=="relevance")
      query += generateRanking(_qstring, i)
     end
     query += ")"
     if i == 1
       query += ")"
     end
     if i < _qoperator.length && _qtype.length > _qoperator.length
       query += " " + _qoperator[i] + " "
     end
     i += 1
   end
   if i  == 1 
     query += ")"
   end
   query += ")"
   
   # If we want to log the whole query
   ActiveRecord::Base.logger.debug("[UtilFormat][generateQuerySolr] generated query : #{query}")
		 
   return query     
  end
  
  #This method generate the block for synonym of _qstring[i] synonymed with _qsynonym[i] and _qtyped[i]
  def self.generateSynonym(_qtype, _qstring, _qsynonym, i)
    exact_search = false
    if (!_qstring[i].blank? and _qstring[i][0]==34 and _qstring[i][_qstring[i].length-1]==34)
      exact_search = true
    end
   exactfield_exist = ["keyword", "creator", "theme", "title", "subject", "author", "document_type", "publisher"]
   value = UtilFormat.normalizeSolrKeyword(_qstring[i]).strip
   solr_field = ""
   if (exact_search and exactfield_exist.include?(_qtype[i]))
      solr_field = _qtype[i] + "_no_stemmed"
   else
      solr_field = _qtype[i]
   end
    
   query = ""
   if !value.blank? 
     query += "("
     case solr_field
        when "indice"
          query += "#{solr_field}:(\"#{value}\")"      
        when "cote_rebond"
          query += "#{solr_field}:(\"#{value}\")"         
     else
      query += "#{solr_field}:(#{value})"
     end

     if (exactfield_exist.include?(solr_field))
       solr_field = "#{solr_field}_no_stemmed"
     end

     # Here we add to the request all of the synonyms
     if (solr_field!="indice" && !_qsynonym.nil? and !_qsynonym[i].nil?)
       # We append to the word the synonyms. Append is done with OR statement
       _qsynonym[i].each do |synom|
          nsynom = UtilFormat.normalizeSolrKeyword(synom).strip
          query += " OR #{solr_field}:(\"#{nsynom}\")"
       end
     else
       ActiveRecord::Base.logger.error("_qsynonym or _qsynonym[i] are NULL - The _qsynonym argument is not correctly passed to UtilFormat")
     end
     query += ")"
   end
   return query
  end
  
  def self.generateRanking(_qstring, i)
    value = UtilFormat.normalizeSolrKeyword(_qstring[i]).strip 
    if !value.blank?
      ranking = " "
      ranking += "OR title:(#{value})^#{TITLE_PERFECT_MATCH} "
      ranking += "OR title_no_stemmed:(#{value})^#{TITLE_PERFECT_MATCH_EXACT} "
      ranking += "OR creator:(#{value})^#{CREATOR_PERFECT_MATCH} "
      ranking += "OR creator_no_stemmed:(#{value})^#{CREATOR_PERFECT_MATCH_EXACT} "
      ranking += "OR subject:(#{value})^#{SUBJECT_PERFECT_MATCH} "
      ranking += "OR subject_no_stemmed:(#{value})^#{SUBJECT_PERFECT_MATCH_EXACT} "
      ranking += "OR theme:(#{value})^#{THEME_PERFECT_MATCH} "
      ranking += "OR theme_no_stemmed:(#{value})^#{THEME_PERFECT_MATCH_EXACT} "
      ranking += "OR indice:(#{value})^#{INDICE_PERFECT_MATCH}"
      return ranking
    else
      return ""
    end
  end
 
  # Generate solr extra query to filter the document
  def self.generateFilter(_t, infos_user, _collections)
    _qreturn = ""
    _t.each {|item|
      name = item[0]
      value = UtilFormat.normalizeSolrKeyword(item[1]).strip
      case name
        when "author"
          _qreturn += "(creator:(\"#{value}\"))"
        when "date"
          range_date = "#{value}-01-01T00:00:00Z TO #{value}-12-31T23:59:30Z"
          _qreturn += "(date_document:[#{range_date}])"
        when "material_type"
         _qreturn += "(document_type:(\"#{value}\"))"
        when "subject"
         _qreturn += "(subject:(\"#{value}\"))"
        when "vendor_name"
         _qreturn += "(collection_name:(\"#{value}\"))"
        when "lang"
         _qreturn += "(lang_exact:(\"#{value}\"))"
        when "theme"
          value = value = UtilFormat.normalizeWithBlankSolrKeyword(item[1]).strip
         _qreturn += "(theme_exact:(#{value}*))"
        when "musical"
          value = value = UtilFormat.normalizeWithBlankSolrKeyword(item[1]).strip
         _qreturn += "(musical_kind_exact:(#{value}*))"
        when "availability"
         _qreturn +=  generateFilterAvailabilityFacet(value, infos_user, _collections)
        when "alpha"
         _qreturn += "(title_list_alpha:(\"#{value}\"))"
      end
    }
    return _qreturn
  end
  
  def self.generateAvailabilityFacet(infos_user, collections)
    location_groups = Array.new
    if !infos_user.nil?
      location_groups = ManageRole.GetBroadcastGroups(infos_user)
    end
    availabilityFacet = Array.new

    free_groups = FREE_ACCESS_GROUPS.split(",")
    joined_broadcast_group = ""
    joined_user_broadcast_group = ""
    
    free_groups.each do |group|
      if joined_broadcast_group == ""
        joined_broadcast_group += "dispo_broadcast_group:(\"#{group}\")"
      else
        joined_broadcast_group += " OR dispo_broadcast_group:(\"#{group}\")"
      end
      
      if !location_groups.nil? and location_groups.include?(group)
        if joined_user_broadcast_group == ""
          joined_user_broadcast_group += "dispo_broadcast_group:(\"#{group}\")"
         else
          joined_user_broadcast_group += " OR dispo_broadcast_group:(\"#{group}\")"
         end
       elsif !location_groups.nil? and !location_groups.include?(group)
        if joined_user_broadcast_group == ""
          joined_user_broadcast_group += "dispo_broadcast_group:(\"#{group}\")"
         else
          joined_user_broadcast_group += " OR dispo_broadcast_group:(\"#{group}\")"
         end
       end
      
    end
    joined_broadcast_group = "("+ joined_broadcast_group + ")"
   
   free_groups.each do |group|   
     if !location_groups.nil? and location_groups.include?(group)
        availabilityFacet[0] = "(dispo_sur_poste:(online) AND #{joined_user_broadcast_group})"
        availabilityFacet[1] = "(dispo_sur_poste:(onshelf))"
        break;
      elsif location_groups.nil?
        availabilityFacet[0] = "(dispo_bibliotheque:(online) AND #{joined_broadcast_group})"
        availabilityFacet[1] = "(dispo_bibliotheque:(onshelf))"
        break;
      elsif !location_groups.nil? and !location_groups.include?(group)
        availabilityFacet[0] = "(dispo_access_libre:(online) AND #{joined_user_broadcast_group})"
        availabilityFacet[1] = "(dispo_access_libre:(onshelf))"
        break;
      else
        availabilityFacet[0] = "(dispo_avec_reservation:(online))"
        availabilityFacet[1] = "(dispo_avec_reservation:(onshelf))"
      end
    end
    
    if(INFOS_USER_CONTROL and !infos_user.nil?)
      liste_authorized_collection_id = ""
      collections.each {|collection|
        droits = ManageDroit.GetDroits(infos_user, collection.id)
        if(!droits.blank? and droits.id_perm == ACCESS_ALLOWED)
          liste_authorized_collection_id += "collection_id:(#{collection.id}) OR "
        end
      }
      if !liste_authorized_collection_id.empty?
        liste_authorized_collection_id = liste_authorized_collection_id.slice(0, liste_authorized_collection_id.length-4)
        liste_authorized_collection_id = "AND (#{liste_authorized_collection_id})"
      end
      
      if availabilityFacet[0].blank?
        availabilityFacet[0] = "(dispo_avec_access_autorise:(online) #{liste_authorized_collection_id})"
      else
        availabilityFacet[0] += " OR (dispo_avec_access_autorise:(online) #{liste_authorized_collection_id}) "
      end
      if availabilityFacet[1].blank?
        availabilityFacet[1] = "(dispo_avec_access_autorise:(onshelf) #{liste_authorized_collection_id})"
      else
        availabilityFacet[1] += " OR (dispo_avec_access_autorise:(onshelf) #{liste_authorized_collection_id})"
      end
    end
    return availabilityFacet;
  end
  
  def self.generateFilterAvailabilityFacet(value, infos_user, collections)
    _qreturn = " ("
    
    tmp_allowed = ""
    if(INFOS_USER_CONTROL and !infos_user.nil?)   
      liste_authorized_collection_id = ""
      collections.each {|collection|
        droits = ManageDroit.GetDroits(infos_user, collection.id)
        if(!droits.blank? and droits.id_perm == ACCESS_ALLOWED)
          liste_authorized_collection_id += "collection_id:(#{collection.id}) OR "
        end
      }
      if !liste_authorized_collection_id.empty?
        liste_authorized_collection_id = liste_authorized_collection_id.slice(0, liste_authorized_collection_id.length-4)
        liste_authorized_collection_id = "AND (#{liste_authorized_collection_id})"
      end
      tmp_allowed = "(dispo_avec_access_autorise:(#{value}) #{liste_authorized_collection_id})"
    end
    
    location_groups = Array.new
    if !infos_user.nil?
      location_groups = ManageRole.GetBroadcastGroups(infos_user)
    end
    tmp_group = ""
    free_groups = FREE_ACCESS_GROUPS.split(",")
    joined_broadcast_group = ""
    free_groups.each do |group|
      if joined_broadcast_group == ""
        joined_broadcast_group += "dispo_broadcast_group:(\"#{group}\")"
      else
        joined_broadcast_group += " OR dispo_broadcast_group:(\"#{group}\")"
      end
    end
    joined_broadcast_group = "("+ joined_broadcast_group + ")"
      
    location_include_group = false
    free_groups.each do |group|
      if !location_groups.nil? and location_groups.include?(group)
        location_include_group = true
        break
      end
    end
    
    
    if value=="online"
      if !location_groups.nil? and location_include_group
        tmp_group = "(dispo_sur_poste:(#{value}) AND #{joined_broadcast_group})"
      elsif location_groups.nil?
        tmp_group = "(dispo_bibliotheque:(#{value}) AND #{joined_broadcast_group})"
      elsif !location_groups.nil? and !location_include_group
        tmp_group = "(dispo_access_libre:(#{value}) AND #{joined_broadcast_group})"
      else
        tmp_group = "(dispo_avec_reservation:(\"#{value}\"))"
      end
    elsif value== "onshelf"
      if !location_groups.nil? and location_include_group
        tmp_group = "(dispo_sur_poste:(#{value}))"
      elsif location_groups.nil?
        tmp_group = "(dispo_bibliotheque:(#{value}))"
      elsif !location_groups.nil? and !location_include_group
        tmp_group = "(dispo_access_libre:(#{value}))"
      else
        tmp_group = "(dispo_avec_reservation:(\"#{value}\"))"
      end    
    end
    
    # merge the 2 different access group
    if tmp_group.length == 0 and tmp_allowed.length == 0
      return ""
    elsif tmp_group.length >0 and tmp_allowed.length >0
      _qreturn += tmp_allowed + " OR " + tmp_group 
    elsif tmp_group.length==0 and tmp_allowed.length >0
     _qreturn += tmp_allowed
    elsif tmp_group.length >0 and tmp_allowed.length == 0
     _qreturn += tmp_group 
    end
    
    return _qreturn + ")";
  end
  
  def self.calculateDateBoost(_date)
    if (_date.kind_of?(Array))
      arr = _date.join().split("-")
    end
    
    if(_date.kind_of?(String))
      arr = _date.split("-")
    end
    
    if(arr.length>0 and arr[0].length == 4 and self.is_number(arr[0]))
      if (arr[0]=="0000")
      arr[0] = "1970"
      end
      date = arr[0]
    else
      date = "1970"
    end
    
    time = Time.new
    delta = time.year.to_f-date.to_f
    if (delta>0)
      boost =  (DATE_BOOST.to_f/(delta))
      if boost <=0
        boost = 0.000001
      end
    else
      boost = 0.000001
    end
    
    return boost
    
  end
  
  def self.normalizeSolrDate(date)
    begin
			arr = date.join().split("-") if date.kind_of?(Array)
			arr = date.split("-") if date.kind_of?(String)
    
			if arr.length > 0 and arr[0].strip.length == 4 and self.is_number(arr[0])
				arr[0] = "1000" if arr[0] == "0000"
				date = arr[0].strip
			else
				match = /\b\d{4}\b/.match(arr[0])
				date = match ? match[0] : "1000"
			end
			 
			if arr.length > 1 and arr[1].length == 2 and arr[1].gsub('0', '').to_i != 0
				arr[1] = "01" if arr[1] == "00"
				date += "-" + arr[1]
			else
				date += "-01"
			end
     
			if arr.length > 2 and arr[2].length == 2 and arr[2].gsub('0', '').to_i != 0 
				arr[2] = "01" if arr[2] == "00"
				date += "-" + arr[2]
			else
				date += "-02"
			end
			 
			date += 'T00:00:00Z'
			return date
    rescue
			return " 1000-01-02T00:00:00Z"
    end
  end
  
  def self.normalizeFerretKeyword(_string)
    return "" if _string == nil
    #the quote isn't escaped because it is actually useful in this case.
    _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
    return _string
  end
  
  def self.normalizeSolrKeyword(_string)
    return "" if _string == nil
    _string.squeeze('-');
    # Escape characters: +-&&||!(){}[]^"~*?:\
    _string = _string.gsub(/([\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
    # Managing double quotes whitin the query string
    if _string.index(/^\".*\"$/) != nil
      _string = _string.slice(1, _string.length() - 2)
      _string = '"' + _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3') + '"'
    else
      _string = _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3')
    end
    return _string
  end
  
  def self.normalizeWithBlankSolrKeyword(_string)
    return "" if _string == nil
    _string.squeeze('-');
    # Escape characters: +-&&||!(){}[]^"~*?:\
    _string = _string.gsub(/([\s\'\:\(\)\[\]\{\}\!\+\~\^\-\|\<\>\=\*\?\\])/, '\\\\\1')
    # Managing double quotes whitin the query string
    if _string.index(/^\".*\"$/) != nil
      _string = _string.slice(1, _string.length() - 2)
      _string = '"' + _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3') + '"'
    else
      _string = _string.gsub(/([.^\"]*)\"([.^\"]*)/, '\1\2\\\"\3')
    end
    return _string
  end
  
  def self.normalizeDate(_string)
    
    return "" if _string.blank?
    
    begin
      out = ""
      _string = _string.gsub(/-/, "")
      arr = _string.split(';')
      arr.each do |item|
      item = item.chomp
        
        # logger.debug("Item: " + item + "\nLength: " + item.length.to_s)
        if item.length <= 10
          _string = _string.gsub(/[^0-9]/, "")
          
          yyyy = "-1"
          mm = "-1"
          dd = "-1"
          
          if _string.length >= 4
            yyyy = _string.slice(0,4)
          end
          
          if _string.length >= 6
            mm = _string.slice(4,2)
          end
          
          if _string.length >= 8 
            dd = _string.slice(6,2)
          end
          
          if yyyy.to_i > 0 and yyyy.to_i < 2500
            out = yyyy
            
            if mm.to_i > 0 and mm.to_i <= 12
              out = "#{out}-#{mm}"
              
              if dd.to_i > 0 and dd.to_i <= 31
                out = "#{out}-#{dd}"
              end
            end
          end
        end
      end
    rescue
    end
    return out
  end
  
  def self.normalize(_string)
    return self.sanitize_utf8(_string).gsub(/[^a-z^A-Z^à^á^â^ã^ä^å^ò^ó^ô^õ^ö^ø^è^é^ê^ë^ç^ì^í^î^ï^ù^ú^û^ü^ÿ^ñ^_^0-9^\)^\]^\[^"^;^[:punct:]]$/,"").to_s.chomp  if _string != nil
    return ""
  end
  
  def self.normalizeLang(lang)
   if lang == nil 
     return ""
   end
   case lang.downcase
     when "fr"
     return "Français"
     when "fr_fr"
     return "Français"
     when "en"
     return "Anglais"
     when "en_en"
     return "Anglais"
     when "en_us"
     return "Anglais"
     when "us"
     return "Anglais"
     when "us_us"
     return "Anglais"
     when "fre"
     return "Français"
     when "de"
     return "Allemand"
     when "es"
     return "Espagnol"
     when "ja"
     return "Japonais"
     when "cn"
     return "Chinois"
   else
     return lang.capitalize
   end
  end
  
  # Return params for id notice
  # call: idDoc, idColl, idSearch = UtilFormat.parseIdDoc(doc)
  def self.parseIdDoc(doc)
    idDoc = nil
    idColl = nil
    idSearch = nil
    if !doc.blank?
      tmp = doc.split(ID_SEPARATOR)
      if tmp.size() >= 2
        idDoc = tmp[0]
        idColl = tmp[1]
      end
      
      if tmp.size() == 3
        idSearch = tmp[2]
      end
    end
    col_id = Integer(idColl)
    
    if(!col_id.is_a?(Integer))
      raise("[UtilFormat][parseIdDoc] Invalid collection id : #{idColl} !!")
    end
    return idDoc, idColl, idSearch
  end
  
  def self.analyzeParams(_qtype,_qstring,_coll_list)
    cpt_type = 0
    while cpt_type < _qtype.length do
      if(_qtype[cpt_type] == 'document_type')
        document_type_cols = DocumentType.getDocumentTypesValues(_qstring[cpt_type],_coll_list)
        if !document_type_cols.nil? and !document_type_cols.empty?
          _qstring[cpt_type] = Array.new
          document_type_cols.each do |type|
            _qstring[cpt_type] << type.document_type_name
          end
        end
      end
      cpt_type += 1
    end
    return _qstring
  end

  def self.remove_accents (str)
    value = str.dup
    accents = { 
      ['á','à','â','ä','ã','Ã','Ä','Â','À'] => 'a',
      ['é','è','ê','ë','Ë','É','È','Ê']     => 'e',
      ['í','ì','î','ï','I','Î','Ì']         => 'i',
      ['ó','ò','ô','ö','õ','Õ','Ö','Ô','Ò'] => 'o',
      ['œ']                                 => 'oe',
      ['ß']                                 => 'ss',
      ['ú','ù','û','ü','U','Û','Ù']         => 'u',
      ['ç']                                 => 'c'
    };
    accents.each do |ac,rep|
      ac.each do |s|
        value.gsub!(s, rep)
      end
    end
    return (value)
  end
  
  # Escape html characters
  def self.html_encode(string)
    coder = HTMLEntities.new
    return coder.encode(string, :basic, :named, :decimal)
  end
  
  # Unescape html characters
  def self.html_decode(string)
    coder = HTMLEntities.new
    return coder.decode(string) 
  end
  
  # format "dd-mm-yyyy"
  # retourne datetime
  # if minuit = set to 00:00:00
  # else set to 23:59:59
  def self.get_date(string, minuit = true, separator='/', format = "%Y-%m-%d %H:%M:%S")
    if (string.blank?)
      return nil
    end
    datetime = nil
    begin
      hour = "00"
      min = "00"
      sec = "00"
      if !minuit
        hour = "23"
        min = "59"
        sec = "59"
      end
      tab = string.split(separator)
      datetime = Time.mktime(tab[2], tab[1], tab[0], hour, min, sec)
      return datetime.strftime(format)
    rescue => e
      ActiveRecord::Base.logger.error("[UtilFormat] [get_date] => #{e.message} with date: #{string}")
    end
    
    return datetime
  end
  
  def self.sanitize_utf8(string)
    utf_reg = /\A(
           [\x09\x0A\x0D\x20-\x7E]        
         | [\xC2-\xDF][\x80-\xBF]         
         |  \xE0[\xA0-\xBF][\x80-\xBF]   
         | [\xE1-\xEC\xEE][\x80-\xBF]{2}
         |  \xEF[\x80-\xBE]{2} 
         |  \xEF\xBF[\x80-\xBD] 
         |  \xED[\x80-\x9F][\x80-\xBF]
         |  \xF0[\x90-\xBF][\x80-\xBF]{2}   
         | [\xF1-\xF3][\x80-\xBF]{3}
         |  \xF4[\x80-\x8F][\x80-\xBF]{2}
       )*\Z/nx;
    return string.split(//u).grep(utf_reg).join
  end
  
  # test is a number is numeric
  def self.is_number(str)
    Integer(str)
  rescue ArgumentError
    false
  else
    true
  end

end
