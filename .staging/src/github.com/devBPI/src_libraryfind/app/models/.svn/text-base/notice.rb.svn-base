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

class Notice < ActiveRecord::Base
  
  set_primary_keys :doc_identifier, :doc_collection_id
  
  has_many :user_records,   :foreign_key => [:doc_identifier, :doc_collection_id], :dependent => :destroy
  
  has_many :subscriptions,  :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_one   :objects_count, :foreign_key => :object_uid, :dependent => :destroy, :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_many :comments,       :foreign_key => :object_uid,  :dependent => :destroy,  :conditions => " object_type = #{ENUM_NOTICE} "
  
  has_many :objects_tags,   :foreign_key => :object_uid,  :dependent => :destroy,  :conditions => " object_type = #{ENUM_NOTICE} "
  
  after_create { |notice| 
    # create count for notice
    ObjectsCount.createCount(ENUM_NOTICE, notice.id) 
  }
  
  
  # doc is idDoc;idColl[;idSearch]
  def self.existsById?(doc)
    idDoc, idColl = UtilFormat.parseIdDoc(doc)
    return Notice.exists?("#{idDoc},#{idColl}")
  end
  
  def self.addOnlyNoExist(record)
    if !existsById?(record.id)
      return addNotice(record) 
    else
      return nil
    end
  end
  
  def self.getListInfosCopy(doc_id)
    logger.debug("[Notice][getListInfosCopy] #{doc_id}")
    ## todo implement
    return true
  end
  
  
  def self.getNoticeByDocId(object_uid)
    logger.debug("[Notice][getNoticeByDocId] #{object_uid}")
    doc_identifier, doc_collection_id = UtilFormat.parseIdDoc(object_uid);
    if doc_identifier.blank? or doc_collection_id.blank?
      logger.error("[Notice][getNoticeByDocId] invalid object_uid: #{object_uid}")
      return nil
    end
    return Notice.find(:first, :conditions => " doc_identifier='#{doc_identifier}' and doc_collection_id=#{doc_collection_id} ");
  end
  
  def self.topByListe(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(*) as total, n.doc_identifier , n.doc_collection_id , alt_name, dc_title, ptitle, dc_type "

    case unit
      when "month"
      req += ", month(l.date_insert) month, year(l.date_insert) year "
      when "year"
      req += ", year(l.date_insert) year "
      when "day"
      req += ", day(l.date_insert) day, month(l.date_insert) month, year(l.date_insert) year "
    end

    req += "FROM notices n, list_user_records as l, collections c "
    req += "WHERE  l.doc_identifier = n.doc_identifier AND l.doc_collection_id = n.doc_collection_id "
    req += "and n.doc_collection_id = c.id "
    
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and l.date_insert >= '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and l.date_insert <= '#{date_to}' "
    end
    
    if (!profil.blank?)
     req += " and log.profil = '#{profil}' "
      
    end
    
    # GROUP BY
    req += " GROUP BY n.doc_identifier, n.doc_collection_id "
    
    
    # CLAUSE ORDER
    req += " ORDER BY "
    
    if (order == "time")
      case unit
        when "month"
        req += "year desc, month desc"
        when "year"
        req += "year desc"
        when "day"
        req += "year desc, month desc, day desc"
      else
        req += "total DESC"
      end
    else
      req += "total DESC"
    end

    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max)
  end
  
  # Only tested with simulation
  def self.topBySubscription(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(*) as subscriptions_count, doc_identifier , doc_collection_id , alt_name, dc_title, ptitle, dc_type "

    case unit
      when "month"
      req += ", month(s.subscription_date) month, year(s.subscription_date) year "
      when "year"
      req += ", year(s.subscription_date) year "
      when "day"
      req += ", day(s.subscription_date) day, month(s.subscription_date) month, year(s.subscription_date) year "
    end

    req += "FROM notices n, collections c, subscriptions as s "
    req += "WHERE s.object_type = #{ENUM_NOTICE} AND SUBSTRING_INDEX(s.object_uid, ';', 2) = CONCAT(CONCAT(n.doc_identifier,';'), n.doc_collection_id) "
    req += "and n.doc_collection_id = c.id  "
    
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and s.subscription_date >= '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and s.subscription_date <= '#{date_to}' "
    end
    
    # GROUP BY
    req += " GROUP BY n.doc_identifier,n.doc_collection_id "
    
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
        req += "subscriptions_count DESC"
      end
    else
      req += "subscriptions_count DESC"
    end
    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max)
  end
  
  def self.topByComment(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(o.object_uid) as total, doc_identifier , doc_collection_id , alt_name, dc_title, ptitle, dc_type "

    case unit
      when "month"
      req += ", month(cmt.comment_date) month, year(cmt.comment_date) year "
      when "year"
      req += ", year(cmt.comment_date) year "
      when "day"
      req += ", day(cmt.comment_date) day, month(cmt.comment_date) month, year(cmt.comment_date) year "
    end

    req += "FROM notices n, objects_counts o, collections c, comments as cmt "
    req += "WHERE o.object_type = #{ENUM_NOTICE} and o.object_uid = CONCAT(CONCAT(n.doc_identifier,','),n.doc_collection_id)  "
    req += "and n.doc_collection_id = c.id AND replace(cmt.object_uid, ';', ',') = o.object_uid "
    
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and cmt.comment_date >= '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and cmt.comment_date <= '#{date_to}' "
    end
    
    
    # GROUP BY
    req += " GROUP BY o.object_uid "
    
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
        req += "total DESC"
      end
    else
      req += "total DESC"
    end

    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max)
  end
  
  def self.topByTag(page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    if page > 0:
      offset = (page.to_i-1) * max.to_i
    end
    req = "select SQL_CALC_FOUND_ROWS COUNT(o.object_uid) as total, doc_identifier , doc_collection_id , alt_name, dc_title, ptitle, dc_type "

    case unit
      when "month"
      req += ", month(o.tag_date) month, year(o.tag_date) year "
      when "year"
      req += ", year(o.tag_date) year "
      when "day"
      req += ", day(o.tag_date) day, month(o.tag_date) month, year(o.tag_date) year "
    end

    req += "FROM objects_tags o, collections c, notices n "
    req += "WHERE o.object_type = #{ENUM_NOTICE} and o.object_uid = CONCAT(CONCAT(n.doc_identifier,';'),n.doc_collection_id) "
    req += "and n.doc_collection_id = c.id  "
    
    date_from = UtilFormat.get_date(date_from_str)

    if (!date_from.nil?)
      req += " and o.tag_date >= '#{date_from}' "
    end
    
    date_to = UtilFormat.get_date(date_to_str, false)
    if (!date_to.nil?)
      req += " and o.tag_date <= '#{date_to}' "
    end
     
    # GROUP BY
    req += " GROUP BY o.object_uid "
    
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
        req += "total DESC"
      end
    else
      req += "total DESC"
    end

    req += " limit #{offset}, #{max}"
    
    return self.execRequest(req, page, max) 
  end
  
  def self.topByNote (page = 1, max=10, unit= "day", date_from_str = nil, date_to_str = nil, profil = nil, order = nil)
    
   if page > 0:
     offset = (page.to_i-1) * max.to_i
   end
   req = "select SQL_CALC_FOUND_ROWS COUNT(o.object_uid) as notes_count, doc_identifier, doc_collection_id, alt_name, dc_title, ptitle, dc_type, AVG(no.note) as notes_avg "

   case unit
     when "month"
     req += ", month(no.note_date) month, year(no.note_date) year "
     when "year"
     req += ", year(no.note_date) year "
     when "day"
     req += ", day(no.note_date) day, month(no.note_date) month, year(no.note_date) year "
   end
   
   req += "FROM notices n, objects_counts o, collections c, notes as no "
   req += "WHERE o.object_type = #{ENUM_NOTICE} and o.object_uid = CONCAT(CONCAT(n.doc_identifier,','),n.doc_collection_id) AND CONCAT(CONCAT(n.doc_identifier,';'),n.doc_collection_id) = no.object_uid "
   req += "AND n.doc_collection_id = c.id"
   
   date_from = UtilFormat.get_date(date_from_str)

   if (!date_from.nil?)
     req += " and no.note_date >= '#{date_from}' "
   end
   
   date_to = UtilFormat.get_date(date_to_str, false)
   if (!date_to.nil?)
     req += " and no.note_date <= '#{date_to}' "
   end
   
   # GROUP BY
   req += " GROUP BY n.doc_identifier, n.doc_collection_id "
   
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
   
   return self.execRequest(req, page, max)
  end
  
  private
  def self.addNotice(record)
    if !record.nil?
      idDoc, idColl = UtilFormat.parseIdDoc(record.id)
      dt_id = DocumentType.getDocumentTypeId(record.material_type, idColl)
      notice = Notice.new(:doc_identifier => idDoc, :doc_collection_id => idColl, :created_at => DateTime::now(), :dc_title => record.ptitle, :dc_author => record.author, :dc_type => record.material_type, :update_date => DateTime::now(), :isbn => record.isbn, :document_type_id => dt_id)
      notice.save!()
      return notice
    end
  end 
  
  def self.updateNoticeDCType(new_name, id_primary_dc_type)
    Notice.update_all("dc_type = '#{new_name.gsub(/'/, "\\\\'")}'", "document_type_id = #{id_primary_dc_type}")
  end
  
  # Method getNoticeByTagAndUser
  def self.getNoticesByTagAndUser(label,uuid) 
    Notice.find_by_sql ["select notices.doc_identifier, notices.doc_collection_id FROM notices, objects_tags, tags where tags.id = objects_tags.tag_id AND tags.label=#{label} AND objects_tags.object_type =1 AND  objects_tags.object_uid LIKE CONCAT(CONCAT(notices.doc_identifier,';'),notices.doc_collection_id) AND objects_tags.uuid=#{uuid}"]
  end
  
  # Method getNoticeByTagAndUser  
  def self.getOtherUsersNotices(label,uuid)
    Notice.find_by_sql ["select objects_tags.uuid, notices.doc_identifier, notices.doc_collection_id FROM notices, objects_tags, tags where tags.id = objects_tags.tag_id AND tags.label = '#{label}' AND objects_tags.object_type =1 AND  objects_tags.object_uid LIKE CONCAT(CONCAT(notices.doc_identifier,';'),notices.doc_collection_id) AND objects_tags.uuid NOT LIKE '#{uuid}' "]
  end
  
  #@Deprecated ---------- Will be deprecated soon
#  def self.topByChamps(champs, page = 1, max=10, unit = "day", date_from_str = nil, date_to_str = nil, specific_tab = nil)
#    
#    if page > 0:
#      offset = (page.to_i-1) * max.to_i
#    end
#    req = "select SQL_CALC_FOUND_ROWS * "
#    case unit
#      when "month"
#      req += ", month(created_at) month, year(created_at) year "
#      when "year"
#      req += ", year(created_at) year "
#      when "day"
#      req += ", day(created_at) day, month(created_at) month, year(created_at) year "
#    end
#    date_from = UtilFormat.get_date(date_from_str)
#    if (!date_from.nil?)
#      req += " and n.created_at > '#{date_from}' "
#    end
#    
#    date_to = UtilFormat.get_date(date_to_str, false)
#    if (!date_to.nil?)
#      req += " and n.created_at < '#{date_to}' "
#    end
#    ####################################################################
#    
#    req += "from notices n, objects_counts o, collections c, #{specific_tab} "
#    req += "where o.object_type = #{ENUM_NOTICE} and o.object_uid = CONCAT(CONCAT(n.doc_identifier,','),n.doc_collection_id) and o.#{champs} > 0 "
#    req += "and n.doc_collection_id = c.id "
#    req += "order by o.#{champs} DESC "
#    req += "limit #{offset}, #{max}"
#    
#    res = Notice.find_by_sql(req)
#    total = 0
#    count = Notice.find_by_sql("SELECT FOUND_ROWS() as total")
#    if (!count.nil? and !count.empty?)
#      total = count[0].total
#    end
#    tab = []
#    res.each do |v|
#      hash = Hash.new()
#      v.attributes.each do |k, v|
#        hash[k] = v
#      end
#      tab << hash
#    end
    
#    return {:result => tab, :count => total, :page => page, :max => max}
#  end
  
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
