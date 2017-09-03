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
class DocumentType < ActiveRecord::Base

  before_update { |document_type|
    begin
      if (!document_type.nil?)
        old_primary = DocumentType.getPrimaryDocumentTypeId(document_type.name, document_type.collection_id)
        if (old_primary != document_type.primary_document_type)
          new_name = nil
          if (document_type.primary_document_type == 1)
            new_name = document_type.name
          else
            new_name = PrimaryDocumentType.getPrimaryDocumentTypeNameById(document_type.primary_document_type)
          end
          Notice.updateNoticeDCType(new_name, document_type.id)
          Collection.update_all("full_harvest = 1", "id = #{document_type.collection_id}")
        end
      end
    rescue => e
        logger.error("[Notice][before_create] Error : " + e.message)
        raise e
    end
  }
  
  def self.getPrimaryDocumentTypeId(dc_type, collId)
    conditions = "#{dc_type}"
    conditions = "name = " + DocumentType.sanitize(conditions) + "and collection_id = #{collId}"
    dc = DocumentType.find(:first, :conditions => conditions)
    if (!dc.nil?)
      return dc.id
    end
    return nil
  end

  def self.getDocTypeIdByPrimaryId(primary_id)
    return DocumentType.find_by_sql("SELECT id FROM document_types WHERE primary_document_type = #{primary_id}")
  end

  def self.save_document_type(dtype,collection_id)
    value = dtype
    dtype_sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['?', dtype])
    default_coll_mat_type = Collection.find(:first, :select => "mat_type", :conditions => "id = #{collection_id}").mat_type
    san = "name = " + PrimaryDocumentType.sanitize("#{default_coll_mat_type}")
    default_coll_mat_type_id = PrimaryDocumentType.find(:first, :select => "id", :conditions => san).id
    if !dtype.blank?
      query = "SELECT primary_document_types.name AS name, primary_document_types.id AS id FROM primary_document_types,document_types WHERE document_types.name = #{dtype_sql} AND document_types.collection_id = #{collection_id} AND primary_document_types.id = document_types.primary_document_type limit 1"
      res = PrimaryDocumentType.find_by_sql(query)
      if !res.nil? and !res.empty?
        if res[0].id != 1
          value = res[0].name
        else
          value = dtype
        end
      else
        p = DocumentType.new
        p.name = dtype
        p.collection_id = collection_id
        p.primary_document_type = default_coll_mat_type_id
        p.save!
        value = dtype
      end
    else
      value = default_coll_mat_type
    end
    return value
  end

  def self.normalizeForSearch(dtype,collection_id)
    if dtype != nil && dtype != ""
      res = PrimaryDocumentType.find_by_sql("SELECT primary_document_types.name AS primary_document_type_name FROM primary_document_types,document_types WHERE document_types.name = '#{dtype}' AND document_types.collection_id = #{collection_id} AND primary_document_types.id = document_types.primary_document_type")
                                                     
      if res.length() > 0
        if(res[0].primary_document_type_name == 'None')
          return dtype
        end
        return res[0].primary_document_type_name
      end
    end
    return ""
  end

  def self.getDateEndNew(dctype,document_date,collection_id)
    if !dctype.nil? and !document_date.nil?
      new_period = PrimaryDocumentType.find_by_sql("SELECT primary_document_types.new_period AS new_period FROM primary_document_types,document_types WHERE document_types.name = '#{dctype}' AND primary_document_types.name != 'None' AND document_types.collection_id = #{collection_id} AND primary_document_types.id = document_types.primary_document_type ")
      if !new_period.nil? and new_period.size > 0        
        date_end_new = Date.parse(document_date)
        date_end_new = date_end_new + new_period[0].new_period.to_i
        date_end_new = date_end_new.to_s + "T23:59:59Z"
        return date_end_new
      end
    end
    return nil
  end

  def self.getDocumentTypeId(dc_type, collection_id)
    if (!dc_type.nil? and !collection_id.nil?)
    	dc_type_sql = ActiveRecord::Base.send(:sanitize_sql_for_conditions, ['?', dc_type])
      dt_id = DocumentType.find_by_sql("SELECT document_types.id as 'document_type_id' FROM document_types, primary_document_types WHERE document_types.collection_id = #{collection_id} and ((primary_document_types.name = #{dc_type_sql} and primary_document_types.id = document_types.primary_document_type) or document_types.name = #{dc_type_sql}) LIMIT 1")
      if (!dt_id.nil? and !dt_id[0].nil? and !dt_id[0].document_type_id.nil?)
        return dt_id[0].document_type_id    
      end
    end
    return nil
  end

  def self.getDocumentTypesValues(pdt,collection_id)
    return DocumentType.find_by_sql("SELECT document_types.name AS document_type_name FROM document_types,primary_document_types WHERE primary_document_types.name = '#{pdt}' AND document_types.collection_id = #{collection_id} AND primary_document_types.id = document_types.primary_document_type ")
  end
end
