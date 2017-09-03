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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def short_abstract(details)
    abstract_length = 230
    h(details.abstract[0, abstract_length - 1])
  end   
  
  def display_icon(details)
    unless !details.nil? and !details.material_type.nil?
      if details.material_type.downcase == 'book' 
        image_tag("/images/book.gif", :border => "0", :size => "30x30", :alt => "Book", :title => "Book")
      elsif details.material_type.downcase == 'article' 
        image_tag("/images/article.gif", :border => "0", :size => "30x30", :alt => "Article", :title => "Article")
      elsif details.material_type.downcase == 'newspaper'
        image_tag("/images/newspaper.gif", :border => "0", :size => "30x30", :alt => "Newspaper", :title => "Newspaper")
      else
        details.material_type
      end  
    end
  end
  
  def display_citation(details)
    citation = "<span style='color: #ce5500; font-style: italic'>"
    citation += h(details.ptitle) + "</span>"
    if !details.volume.nil? and details.volume.blank?
      citation += "<span style='color: #ce5500'><text>, </text>"
      citation += h(details.volume) 
      unless details.issue.nil? or details.issue.blank?
        citation += "<text>(</text>"
        citation += "#{h_details.issue}<text>)</text>"
      end
      citation += "<text>, </text>#{details.page}" unless details.page.nil? and details.page.blank?
      citation += "</span>"
    else
      citation += "<span style='color: #ce5500'>"
      citation += "<text>, p.</text>#{details.page}" unless details.page.blank?
      citation += "</span>"
    end
    citation
  end
  
  def display_source(details)
    if !details.publisher.blank?
      from = details.publisher
    else
			from = details.title.blank? ? details.vendor_name : details.title
   	end
    
    unless from.nil? or from.blank?
      from.strip!
      length = from.length
      from = from[0, length - 1] if from[length - 1, 1] == ';' or from[length - 1, 1] == ','
    end
    h(from) 
  end
  
  def format_date_range(record) 
    date_string = record.date.to_s
    if record.material_type.downcase != "finding aid"
      date_string = format_date(record)
    else
			date_string = [record.date[0,4], record.date[4,4]].join("-") if record.date.length == 8
    end  
    date_string
  end
  
  def format_date(record)
    if record.material_type.downcase == "finding aid"
      format_date_range(record)
    else
      date = record.date
      year = date[0,4]
      month = ''
      day = ''
      if date.length > 4
        month_num = date[4,2]
        month = case month_num
          when "01" then "JAN"
          when "02" then "FEB"
          when "03" then "MAR"
          when "04" then "APR"
          when "05" then "MAY"
          when "06" then "JUN"
          when "07" then "JUL"
          when "08" then "AUG"
          when "09" then "SEP"
          when "10" then "OCT"
          when "11" then "NOV"
          when "12" then "DEC"
        else           ""
        end
      end
      day = date[6,2] if date.length > 6 and date[6,2] != "00"
      date_string = ''
      unless date == "00000000"
        date_string += month
				date_string = [date_string, day].join(" ") unless day.blank?
				date_string += ', ' unless month.blank? or day.blank?
        date_string += year
      end
      date_string
    end
  end
  
  def display_date(details)   
    if details.material_type.downcase == "finding aid"
      date_string = "<span id='date'>#{format_date_range(details)}</span>"
    else
      date_string = ''
      id = 'date'
      unless details.date == "00000000"
        current_date_string = build_current_date_string
        if current_date_string < details.date
          id = "date-future"
          date_string = "Arriving: "
        end
        date_string ="<span id=#{id}>#{date_string + format_date(details)}</span>"
      end
    end
    date_string
  end
  
  def build_current_date_string
    # Should return YYYYMMDD
    Time.now.iso8601[0..9].delete('-')
  end
  
  def lf_paginate(records, page, page_size)
    return [], [] if records.nil? or records.empty?
    num_links = 15
    added_links = 7
    
    results_count = records.length
    # @page => "Which page we're showing"
    if !page.blank?
      page = page.to_i
    else
      page = 1
    end
    
    if !page_size.blank?
      page_size = page_size.to_i
    else
      page_size = 1
    end
    
    show_previous = false
    show_next = false
    page_list = []
    
    # Check for obvious errors
    #for this case, we add @page_size to the result count to handle the case of the last page
    if results_count + page_size <= (page * page_size)
      return
    elsif page <= 0 
      return
    end
    
    # Limit the result set to this page
    start_item = (page - 1) * page_size
    finish_item = (page * page_size)
    finish_item = results_count if finish_item > results_count
    results_page = records[start_item...finish_item]
    
#    # Should we show the "Previous" link?
#    if page != 1
#      show_previous = true
#      previous = page - 1
#    end
#    
#    # Should we show the "Next" link?
    num_pages = (results_count / Float(page_size)).ceil
#    if page < _num_pages
#      show_next = true
#      pnext = page + 1
#    end
    # Find the page num range to display
    first_page = page - added_links
    first_page = 1 if first_page < 1 or num_pages <= num_links
    last_page = first_page + num_links
    last_page = num_pages + 1 if last_page > num_pages
    page_list = first_page ... num_pages + 1
    return page_list, results_page
  end
  
  def escape_quote(string)
    new_string = string.to_s.gsub('"') {"&quot;"}
    new_string = new_string.to_s.gsub("'") {"&apos;"}
    new_string
  end
  
  def get_total_hits
    hits = 0
    unless @all_databases.nil? or @all_databases.empty?
      @all_databases.each do |d| 
        hits += d[:total_hits].to_i
      end
    end
    hits
  end
  
  def build_unfilter_string(key)
    filter = Array.new(@filter)
    filter.delete_if do |filter_pair|
      filter_pair.include?(key)
    end
    filter_string = build_string_from_filter(filter)
    filter_string
  end
  
  
  def build_filter_string(key, value)
    new_filter = [key,value]
    filter = Array.new(@filter)
    filter << new_filter unless filter.include?(new_filter)
    filter_string = build_string_from_filter(filter)
    filter_string
  end
  
  def build_string_from_filter(filter)
    filter_array = Array.new
    for i in 0..filter.length
      unless filter[i].nil? or filter[i].empty?
        filter_array[i] = filter[i].join(FILTER_SEPARATOR)
      end
    end
    filter_string = filter_array.join("/")
    filter_string
  end
  
  def top_images
    image_results=Array.new(@all_results)
    image_results.delete_if {|record| record.material_type == nil or record.material_type.downcase != "image"}
    image_results
  end
  
  def get_controller_path(caller)
    return controller.controller_path.to_s
  	rescue
    	if !caller.nil?
      	base_path = caller.base_path.to_s
	      base_index = base_path.rindex('/')
  	    if base_index.nil? or base_path.blank?
    	    base = "application" 
      	else
        	base = base_path[base_index + 1, base_path.length]
	      end
  	    return base.to_s
    	else
      	return self.controller_path.to_s
    	end
  end
  
  def translate(key, args=[], caller = nil, file = nil)
		begin
			language = session[:langue] 
		rescue
		end
    
    if language.nil?
      config = YAML::load_file("#{RAILS_ROOT}/config/config.yml")
      language = config["LANGUAGE"]
	  	begin
				session[:langue] = language
	  	rescue
	  	end
    end
    
    if file.nil?
      file= "#{RAILS_ROOT}/app/languages/#{get_controller_path(caller).to_s}_lang.yml"
    else
      file = "#{RAILS_ROOT}/app/languages/#{file}_lang.yml"
    end
    translations ||= YAML::load_file(file.to_s)
    new_string = translations[language][key]
    if new_string.nil?
        app_translations ||= YAML::load_file("#{RAILS_ROOT}/app/languages/application_lang.yml")
        new_string = app_translations[language][key]
        new_string = key if new_string.nil?
    end 
    if !args.nil? and args.length > 0
      i = 0
      args.each do |v|
        key = "\#\{args[#{i}]}"
        new_string = new_string.gsub(key, v)
        i += 1
      end
    end
    new_string
  end
  
  def strip_quotes(record)
    record.vendor_name.delete!("'")
    record.subject.delete!("'") 
    record.author.delete!("'") 
    record.date.delete!("'") 
    record.lang = "" if record.lang.nil?
    record.lang.delete!("'") 
  end
  
end
