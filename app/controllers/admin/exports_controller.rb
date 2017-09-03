# -*- coding: utf-8 -*- 
require 'csv'
class Admin::ExportsController < ApplicationController
  include ApplicationHelper
  
  layout 'admin'
  before_filter :authorize, :except => 'login', :role => 'administrator', :msg => 'Access to this page is restricted.'

	def themes
		file = File.open('/var/tmp/themes.csv', 'wb')
		CSV::Writer.generate(file) do |csv|
			SearchTab.all.each do |tab|
				csv << [tab.label]
				SearchTabSubject.find(:all, :conditions => {:tab_id => tab.id}).each do |sub|
					if sub.parent_id == 0
						csv << [sub.label]
						SearchTabSubject.find(:all, :conditions => {:parent_id => sub.id}).each do |sub2|
							label = sub2.collection_group.nil? ? sub2.label : sub2.label + ' (' + sub2.collection_group.name + ')'
							csv << ['', label]
							SearchTabSubject.find(:all, :conditions => {:parent_id => sub2.id}).each do |sub3|
								label = sub3.collection_group.nil? ? sub3.label : sub3.label + ' (' + sub3.collection_group.name + ')'
								csv << ['', '', label]
								SearchTabSubject.find(:all, :conditions => {:parent_id => sub3.id}).each do |sub4|
									label = sub4.collection_group.nil? ? sub4.label : sub4.label + ' (' + sub4.collection_group.name + ')'
									csv << ['', '', label]
									SearchTabSubject.find(:all, :conditions => {:parent_id => sub4.id}).each do |sub5|
										label = sub5.collection_group.nil? ? sub5.label : sub5.label + ' (' + sub5.collection_group.name + ')'
										csv << ['', '', label]
									end
								end
							end
						end
					end
				end
			end
		end
		file.close

		respond_to do |format|
			format.csv { send_file '/var/tmp/themes.csv' }
		end
	end

	def groups
		file = File.open('/var/tmp/collection_groups.csv', 'wb')
		CSV::Writer.generate(file) do |csv|
			CollectionGroup.all.each do |cg|
				tab = cg.search_tab.nil? ? '' : cg.search_tab.label
				csv << [cg.name + ' (' + cg.full_name + ', ' + tab + ')']
				cg.collection_group_members.each do |member|
					csv << [member.collection.name, member.filter_query]
				end
				csv << []
			end
		end
		file.close

		respond_to do |format|
			format.csv { send_file '/var/tmp/collection_groups.csv' }
		end
	end
  
  def crawler
		sql =  "SELECT v.label, v.link, p.theme, p.publisher_country, m.dc_language, "
		sql += "v.dc_identifier, v.source, v.document_id, v.object_id "
		sql += "FROM volumes v, portfolio_datas p, metadatas m "
		sql += "WHERE v.metadata_id = m.id "
		sql += "AND p.metadata_id = m.id "
		sql += "AND m.collection_id = 5 "
		sql += "AND link <> '' "
		sql += "AND link NOT LIKE '%editionsdelabibliotheque%' "
		sql += "AND LOWER(m.dc_rights) LIKE '%consultation libre sur le web%' "
		#sql += "LIMIT 50 "
		#sql += "AND p.dc_identifier IN (881759)"

		results = ActiveRecord::Base.connection.execute(sql)

		file = File.open('/var/tmp/crawler.csv', 'wb')
		CSV::Writer.generate(file) do |csv|
			csv << ['name', 'starting_url', 'collection', 'country', 'language', 'metadata']
			results.each do |row| 
				row.each_with_index do |r, idx| 
					unless r.nil?
						row[idx] = nil if r.blank?
						if idx == 2 and !row[idx].nil?
							themes = row[2].gsub(',', '-')
							final_themes = []
							themes.split(';').each do |theme|
								final_themes << theme.split('>').shift(2).join('>')	
							end
							row[2] = final_themes.uniq.join(';')
						end
					end
				end
				row[5] = row[5..8].join('_')
				[8,7,6].each {|idx| row.delete_at(idx)}
				csv << row
			end
		end
		file.close

		respond_to do |format|
			format.csv { send_file '/var/tmp/crawler.csv' }
		end
  end

end

