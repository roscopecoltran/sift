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
# http://libraryfind.org

class ThemesImport
  
  ###########################################################################################################################
	# This class imports LF shared themes and the mappings between theses themes and the cdu cote or bdm themes (using apkid)
	# CSV files in components/themes are used (one per bdm + cdu) 
	# We get the source name using the csv file name
  ###########################################################################################################################

	ENV['LIBRARYFIND_HOME'] = ENV['LIBRARYFIND_HOME'].nil? ? "../" : ENV['LIBRARYFIND_HOME']
  
	require 'rubygems'
	require 'yaml'
	require 'iconv'
	require ENV['LIBRARYFIND_HOME'] + 'config/environment.rb'
	require ENV['LIBRARYFIND_HOME'] + 'app/models/themes_reference'
	require ENV['LIBRARYFIND_HOME'] + 'app/models/theme'

	RAILS_ROOT = "#{File.dirname(__FILE__)}/.." unless defined?(RAILS_ROOT)
	CSV_SEPARATOR = "@"
	CSV_PATH = "#{RAILS_ROOT}/components/themes/"
	REF_SEPARATOR = ";"
  
	# Database connexion
	def initialize
		@db = YAML::load_file(ENV['LIBRARYFIND_HOME'] + "config/database.yml")
		@dbtype = 'production'
    
		if defined? @db[@dbtype]["port"]
			ActiveRecord::Base.establish_connection(
				:adapter => @db[@dbtype]["adapter"],
				:host => @db[@dbtype]["host"],
				:username => @db[@dbtype]["username"],
				:password => @db[@dbtype]["password"],
				:database => @db[@dbtype]["database"]
			)
		else
			ActiveRecord::Base.establish_connection(
				:adapter => @db[@dbtype]["adapter"],
				:host => @db[@dbtype]["host"],
				:username => @db[@dbtype]["username"],
				:password => @db[@dbtype]["password"],
				:database => @db[@dbtype]["database"],
				:port => @db[@dbtype]["port"]
			)
		end
	end

  # Delete all themes and themes references
  def delete
    ThemesReference.delete_all
    Theme.delete_all
		puts "Shared themes and references deleted."
  end

	# IMPORTING SHARED THEMES ####################################################################

  # Read the file themes.csv 
  def import_themes
		puts "Reading themes.csv..."
		nb_themes = 0
    File.open("#{CSV_PATH}themes.csv").each do |line|
			line = line.split(CSV_SEPARATOR)
      unless line[0].blank?
        parent = line[3] == 0 ? nil : line[3]
        rang = line.size > 4 ? line[4].strip : nil
        addTheme(line[0].strip, line[1].strip.delete("\""), line[2].strip, rang, parent)
				nb_themes += 1
      end
    end
		puts "#{nb_themes} themes imported!"
  end
  
  # Save theme in the database
  def addTheme(ref, label, level, sort, parent = nil)
		theme = Theme.new
		theme.reference = ref
		theme.label = Iconv.conv('UTF-8', 'ISO-8859-1', label)
		theme.sort = sort.nil? ? 1 : sort
		theme.level = level
		theme.parent = parent
    theme.save!
    return theme
  end

	# IMPORTING REFERENCES ################################################################

  # Normalize cotes or apkid (remove trailing spaces and double cotes, replacing [espace] by actual spaces)
  def normalizeReferences(references)
		references= references.split(REF_SEPARATOR).collect {|ref| ref.strip.gsub("[espace]", " ")}
		return references
  end

  # Reading CSV files
  def import_references
		Dir.glob("#{CSV_PATH}mapping*.csv") do |file|
			puts "Reading #{file}..."			
			source = file.match(/mapping_([^\/.]*).csv$/)[1]
   		ref_hash = Hash.new
			excl_hash = Hash.new
    	File.open(file).each do |line|
				line = line.split(CSV_SEPARATOR)
      	theme = line[0]
	      references = line[1]
				exclusions = line[2]
				unless references.blank?
					ref_hash[theme] = normalizeReferences(references)
  	    end
				unless exclusions.blank?
					excl_hash[theme] = normalizeReferences(exclusions)
				end
    	end
    	ThemesReference.create_references(ref_hash, source, excl_hash)
		end
  end

  def run
    delete
    import_themes
   	import_references 
  end
  
end

runner = ThemesImport.new
runner.run
