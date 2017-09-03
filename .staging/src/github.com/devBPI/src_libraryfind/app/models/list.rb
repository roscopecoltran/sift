# LibraryFind - Quality find done better.
# Copyright (C) 2007 Oregon State University
# Copyright (C) 2009 Atos Origin France - Business Innovation
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

require 'rubygems'
require 'composite_primary_keys'

class List < ActiveRecord::Base
  
  has_many :list_user_records, :dependent => :destroy
  
  has_many :user_records, :through => :list_user_records
  
  belongs_to :community_users, :foreign_key => :uuid
  
  has_many :comments, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_LIST} "
  
  has_many :objects_tags, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_LIST} "
  
  has_one :objects_count, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_LIST} "
  
  after_create { |liste| 
    # create count for liste
    ObjectsCount.createCount(ENUM_LIST, liste.id)
    
    # increment lists_count for user
    ObjectsCount.incrementObjectsCount(ENUM_COMMUNITY_USER, liste.uuid, ENUM_LIST, 1, liste.state) 
    
    log_management = LogManagement.instance
    log_management.addLogListConsult(liste, 1)
  }
  
  after_destroy { |list|
    # decrement lists_count for user
    ObjectsCount.decrementObjectsCount(ENUM_COMMUNITY_USER, list.uuid, ENUM_LIST, 1, list.state) 
    
    log_management = LogManagement.instance
    log_management.addLogListConsult(list, 0)
  }
  
  #update state dependance when chnage state on list
  before_update { |list|
    obj = List.find(list.id)
    if !obj.nil?
      if (list.state != obj.state)
        #update user list count
        oc = ObjectsCount.getObjectCountById(ENUM_COMMUNITY_USER, list.uuid)
        if(!oc.nil?)
          ObjectsCount.updateListsCountPublic(oc, 1, list.state)
        end
        
        #update notices list count
        nc = ListUserRecord.find(:all, :conditions => "list_id = #{list.id}")
        nc.each do |notice|
          oc = ObjectsCount.getObjectCountById(ENUM_NOTICE, "#{notice.doc_identifier},#{notice.doc_collection_id}")
          if(!oc.nil?)
            ObjectsCount.updateListsCountPublic(oc, 1, list.state)
          end
        end
        
        #update tags list count
        tc = ObjectsTag.find(:all, :conditions => "object_type = #{ENUM_LIST} and object_uid = '#{list.id}'")
        tc.each do |tag|
          oc = ObjectsCount.getObjectCountById(ENUM_TAG, tag.tag_id)
          if(!oc.nil?)
            ObjectsCount.updateListsCountPublic(oc, 1, list.state)
          end
        end
      end
    end
  }
  
  def self.createList(title, ptitle, uuid, description, state)
    list = List.new("title" => title, "ptitle" => ptitle, "uuid" => uuid, "description" => description, "state" => LIST_PRIVATE, "created_at" => DateTime::now(), "updated_at" => DateTime::now())
    list.state = state
    list.save
    return list.id
  end
  
  def self.updateList(list_id, title, ptitle, uuid, description, state)
    list = List.find(list_id)
    list.title = title
    list.ptitle = ptitle
    list.description = description
    list.updated_at = DateTime::now()
    list.state = state
    list.save
    return list.id
  end
  
  def self.changeState(list_id, state, dateBegin=nil, dateEnd=nil)
    list = List.find(list_id)
    
    if state == LIST_PUBLIC
      list.state = state
      list.date_public = dateBegin
      list.date_end_public = dateEnd
    elsif state == LIST_PRIVATE
      list.state = state
      list.date_public = nil
      list.date_end_public = nil
    else
      raise "State for List Not Found"
    end
    list.save
    return list.id
  end
  
  def self.deleteList(list_id, uuid)
    List.destroy(list_id)
    return true
  end
  
  def self.getNoticeLists(doc_id, uuid)
		query = "SELECT lists.title, list_id FROM lists, list_user_records WHERE lists.id = list_user_records.list_id and (lists.state = #{LIST_PUBLIC} or lists.uuid= '#{uuid}' ) and list_user_records.doc_identifier =  '#{doc_id}' ORDER BY date_insert DESC LIMIT 3"
		List.transaction do
			return ListUserRecord.find_by_sql(query)
		end
  end
  
  def self.getListByUser(uuid, state = nil)
    if state.nil?
      return List.find(:all, :conditions => ["uuid = ?", uuid])
    else
      return List.find(:all, :conditions => ["uuid = ? and state = ?", uuid, state])
    end
  end
  
  def self.getListById(list_id)
    return List.find(:first, :conditions => " id = #{list_id} ")
  end
  
  def self.getListByUserAndState(list_id, uuid = nil)
    if (!uuid.nil?)
      condition = " or uuid = '#{uuid}'"
    end
    return List.find(:first, :conditions => " id = #{list_id} and (state = #{LIST_PUBLIC} #{condition})")
  end
  
  
  def self.exists?(list_id)
    l = List.find(:first, :conditions => ["id = #{list_id}"])
    if l.nil?
      return false
    else
      return true
    end
  end
  
  def self.getListByIdAndUser(list_id, uuid)
    return List.find(:first, :conditions => " id = #{list_id} and uuid = '#{uuid}' ")
  end
  
  def self.updateAllUserListsState(uuid, state)
		lists = List.find(:all, :conditions => "uuid = '#{uuid}'")
		lists.each do |list|
			list.state = state
			list.save
		end
  end
  
  def self.getListsByNotice(doc_id, list_max = DEFAULT_MAX_LIST, page = DEFAULT_PAGE_LIST)
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(doc_id)
    return List.find_by_sql("SELECT * FROM lists,list_user_records WHERE lists.id = list_user_records.list_id AND list_user_records.doc_identifier = '#{doc_identifier}' AND list_user_records.doc_collection_id = #{doc_collection_id} LIMIT #{page},#{list_max} ")
  end
  
  
  def self.topByNotice (page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    #return self.topByChamps("notices_count", page, max)
    if page > 0:
         offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(doc_identifier) as notices_count, id, title"
    case unit
      when "month"
      req += ", month(o.date_insert) month, year(o.date_insert) year "
      when "year"
      req += ", year(o.date_insert) year "
      when "day"
      req += ", day(o.date_insert) day, month(o.date_insert) month, year(o.date_insert) year "
      end
    req += " from lists l, list_user_records o "
    req += "where  o.list_id = l.id"
     
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and o.date_insert >= '#{date_from}' "
    end
     
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and o.date_insert <= '#{date_to}' "
    end
          
     # GRoup BY
    req += " GROUP BY o.list_id "
     
     
     # CLAUSE ORDER
    req += " order by "
     
    if (order == "time")
      case unit
        when "month"
        req += "year desc, month desc"
        when "year"
        req += "year desc"
        when "day"
        req += "year desc, month desc, day desc"
      else
        req += "notices_count DESC"
      end
    else
      req += "notices_count DESC"
    end
   
       req += " limit #{offset}, #{max}"
     
     return self.execRequest(req, page, max)
  end 

  def self.topBySubscription(page = 1, max=10)
    return self.topByChamps("subscriptions_count", page, max) 
  end
  
  def self.topByComment(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    #return self.topByChamps("comments_count", page, max)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(*) as comments_count, l.id, l.title"
    case unit
      when "month"
      req += ", month(cmt.comment_date) month, year(cmt.comment_date) year "
      when "year"
      req += ", year(cmt.comment_date) year "
      when "day"
      req += ", day(cmt.comment_date) day, month(cmt.comment_date) month, year(cmt.comment_date) year "
    end
    req += " from lists l, comments as cmt "
    req += " WHERE cmt.object_type = #{ENUM_LIST} and cmt.object_uid = l.id "
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and cmt.comment_date >= '#{date_from}' "
    end
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and cmt.comment_date <= '#{date_to}' "
    end
        
    # GRoup BY
    req += " GROUP BY l.id "
    
    
    # CLAUSE ORDER
    req += " order by "
    
    if (order == "time")
      case unit
        when "month"
        req += "year desc, month desc"
        when "year"
        req += "year desc"
        when "day"
        req += "year desc, month desc, day desc"
      else
        req += "comments_count DESC"
      end
    else
      req += "comments_count DESC"
    end

    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max) 
  end
  
  def self.topByTag(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    #return self.topByChamps("tags_count", page, max)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(*) as tags_count, l.id, l.title"
    case unit
      when "month"
      req += ", month(log.created_at) month, year(log.created_at) year "
      when "year"
      req += ", year(log.created_at) year "
      when "day"
      req += ", day(log.created_at) day, month(log.created_at) month, year(log.created_at) year "
    end
    req += " from lists l, log_tags as log"
    req += " WHERE log.object_type = #{ENUM_LIST} and log.object_uid = l.id "
    date_from = UtilFormat.get_date(date_from_str)
 
    if (!date_from.nil?)
      req += " and log.created_at >= '#{date_from}' "
    end
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and log.created_at <= '#{date_to}' "
    end
    
    # GROUP BY
    req += " GROUP BY l.id "
    
    
    # CLAUSE ORDER
    req += " order by "
    
    if (order == "time")
      case unit
        when "month"
        req += "year desc, month desc"
        when "year"
        req += "year desc"
        when "day"
        req += "year desc, month desc, day desc"
      else
        req += "tags_count DESC"
      end
    else
      req += "tags_count DESC"
    end

    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max)  
  end
  
  def self.topByNote(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS *"
    case unit
      when "month"
      req += ", month(log.created_at) month, year(log.created_at) year "
      when "year"
      req += ", year(log.created_at) year "
      when "day"
      req += ", day(log.created_at) day, month(log.created_at) month, year(log.created_at) year "
    end
    req += " from lists l, log_notes log  "
    req += "WHERE notes_count > 0 AND log.object_uid = l.id"
    date_from = UtilFormat.get_date(date_from_str)
    if (!date_from.nil?)
      req += " and log.created_at >= '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and log.created_at <= '#{date_to}' "
    end
    # GRoup BY
       req += " GROUP BY l.id "
    # CLAUSE ORDER
      req += " order by "
      
      if (order == "time")
        case unit
          when "month"
          req += "year desc, month desc"
          when "year"
          req += "year desc"
          when "day"
          req += "year desc, month desc, day desc"
        else
          req += "notes_avg DESC"
        end
      else
        req += "notes_avg DESC"
      end
  
    req += " limit #{offset}, #{max}"
    res = List.find_by_sql(req)
    total = 0
    count = List.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
    
  private
  
  def self.topByChamps(champs, page, max, unit, date_from_str, date_to_str, profil, order)
    
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    
    req = "select SQL_CALC_FOUND_ROWS * "
        case unit
          when "month"
          req += ", month(log.created_at) month, year(log.created_at) year "
          when "year"
          req += ", year(log.created_at) year "
          when "day"
          req += ", day(log.created_at) day, month(log.created_at) month, year(log.created_at) year "
        end
    req += "from lists l, objects_counts o, log_notes log "
    req += "where o.object_type = #{ENUM_LIST} and o.object_uid = l.id and o.#{champs} > 0 "
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and log.created_at >= '#{date_from}' "
    end
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and log.created_at <= '#{date_to}' "
    end
    req += "order by o.#{champs} DESC "
    req += "limit #{offset}, #{max}"
    res = List.find_by_sql(req)
    total = 0
    count = List.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    return {:result => tab, :count => total, :page => page, :max => max}
  end
  
  def self.execRequest(req, page, max)
    res = Notice.find_by_sql(req)
    total = 0
    count = Notice.find_by_sql("SELECT FOUND_ROWS() as total")
    if (!count.nil? and !count.empty?)
      total = count[0].total
    end
    tab = []
    res.each do |v|
      hash = Hash.new()
      v.attributes.each do |k, v|
        hash[k] = v
      end
      tab << hash
    end
    
    return {:result => tab, :count => total, :page => page, :max => max}
  end
  
end
