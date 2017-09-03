# $Id: collection_group.rb 1012 2007-07-13 06:58:03Z reeset $

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

class CollectionGroup < ActiveRecord::Base
  
  has_many :collection_group_members, :dependent => :destroy
  has_many :collections, :through => :collection_group_members
  has_many :editorial_group_members, :dependent => :destroy
  has_many :editorials, :through => :editorial_group_members
  has_many :searchTabSubjects, :dependent => :nullify
	belongs_to :search_tab, :foreign_key => :tab_id

	def getAllCollectionsOrdered
		collections = []
		unless self.collections.nil? || self.collections.empty?
			collections = self.collections.sort_by{ |col| col.alt_name }
		end
		return collections
	end

  def self.get_all(bool_advanced=false)
    advanced = "" #tab_id > 0 "
    if bool_advanced
	     advanced += "and display_advanced_search = 1"
    end
    return CollectionGroup.find(:all, :conditions => advanced, :order => 'tab_id, rank')
  end
  
  def self.findByTabNameAndType(tab_name, type = SYNCHRONOUS_GROUP_COLLECTION)
    sql =   "SELECT cg.id, cg.full_name, c.alt_name FROM collection_groups as cg, search_tabs as t, collections as c, collection_group_members as cm "
    sql +=  "WHERE t.id = cg.tab_id AND t.label= '#{tab_name}' AND  cg.id=cm.collection_group_id AND c.id=collection_id AND cg.collection_type =" + type.to_s
    
    result = CollectionGroup.find_by_sql(sql)
    
    _orm = Hash.new
    _col = Hash.new
    result.each{|_r|
      if (_col[_r['id']].blank?)
        _col[_r['id']] = Array.new
        _orm[_r['id']] = {:id => _r['id'], :full_name => _r['full_name']}
      end
      _col[_r['id']] << _r['alt_name']
    }
    
    r_array = Array.new
    _orm.each{|_o|
      r_array << {:id=> _o[1][:id], :full_name => _o[1][:full_name], :collections => _col[_o[1][:id]]} 
    }
    return r_array
   
  end
  
  def self.get_asynchronous_collection(bool_advanced=false)
    advanced = " collection_type <> " + SYNCHRONOUS_GROUP_COLLECTION.to_s #tab_id > 0 "
    if bool_advanced
       advanced += " AND display_advanced_search = 1"
    end
    return CollectionGroup.find(:all, :conditions => advanced, :order => 'tab_id, rank')
  end

  def self.get_list_alpha_id(tab_id)
    sql = "SELECT c.id FROM collection_groups as c, search_tabs as st "
    sql += "WHERE st.label='#{tab_id.to_s}' AND st.id=c.tab_id  AND c.collection_type=4 "
    return CollectionGroup.find_by_sql(sql)
  end

  def self.get_item(id) 
    begin
      return CollectionGroup.find(id)
    rescue
      return nil
    end
  end

  def self.get_item_by_name(name)
    return CollectionGroup.find(:all, :conditions => "name='#{name}'")
  end

  def self.get_members(id)
    return CollectionGroupMember.find(:all, :conditions => "collection_group_id=#{id.to_i}")
  end
  
  def self.get_members_with_name(id)
    sql =   "SELECT c.name, c.url, c.alt_name as full_name, 'O' as hits FROM collection_group_members as cgm, collections as c "
    sql +=  "WHERE c.id = cgm.collection_id AND cgm.collection_group_id =" + id.to_s 
            
    return CollectionGroup.find_by_sql(sql)
  end

  def self.get_parents(id)
    return CollectionGroupMember.find(:all, :conditions => "collection_id=#{id.to_i}")
  end
  
  def self.checkExclusiveDefaultCollection(params)
    sql =   "SELECT id FROM collection_groups "
    sql +=  "WHERE tab_id = #{params[:collection_group][:tab_id]} AND collection_type = #{DEFAULT_ASYNCHRONOUS_GROUP_COLLECTION} "
    if (params[:id]!=nil && params[:id]!="")
      sql +=  "AND id <> #{params[:id]}"
    end  
    
        
    res = CollectionGroup.find_by_sql(sql)
    if(res.size == 0)
      return true
    else
      return false
    end
  end
  
  def self.checkExclusiveDefaultCollectionForAlphabeticList(params)
    sql =   "SELECT id FROM collection_groups "
    sql +=  "WHERE tab_id = #{params[:collection_group][:tab_id]} AND collection_type = #{ALPHABETIC_GROUP_LISTE} "
    if (params[:id]!=nil && params[:id]!="")
      sql +=  "AND id <> #{params[:id]}"
    end  
    
        
    res = CollectionGroup.find_by_sql(sql)
    if(res.size == 0)
      return true
    else
      return false
    end
  end
  
  def self.checkExclusiveRank(params)
    sql =   "SELECT id FROM collection_groups "
    sql +=  "WHERE tab_id = #{params[:collection_group][:tab_id]} AND rank = #{params[:collection_group][:rank]} "
    if (params[:id]!=nil && params[:id]!="")
      sql +=  "AND id <> #{params[:id]}"
      actual_rank = CollectionGroup.find_by_sql("SELECT rank FROM collection_groups WHERE id=#{params[:id]}")
      target_rank = params[:collection_group][:rank]
    else
      CollectionGroup.update_all('rank = rank + 1', "id <> '#{params[:id]}' AND '#{params[:collection_group][:tab_id]}' = tab_id")
    end  
    res = CollectionGroup.find_by_sql(sql)
    if(res.size != 0)
      if  (target_rank.to_i > actual_rank[0].rank.to_i)
        CollectionGroup.update_all('rank = rank - 1', "id <> '#{params[:id]}' AND '#{target_rank}' >= rank AND  '#{actual_rank[0].rank}' < rank AND '#{params[:collection_group][:tab_id]}' = tab_id")
     else 
        CollectionGroup.update_all('rank = rank + 1', "id <> '#{params[:id]}' AND '#{actual_rank[0].rank}' > rank AND '#{target_rank}' <= rank AND '#{params[:collection_group][:tab_id]}' = tab_id")
      end

      
      return true
    else
      return false
    end
  end
  
  def self.getCollectionGroupFullNameById(cg_id)
    cg = CollectionGroup.find(:first, :conditions => " id = #{cg_id.to_i}")
    if(!cg.nil?)
      return cg.full_name
    else
      return "None"
    end
    
  end
end
