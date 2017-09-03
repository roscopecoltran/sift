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

class ThemesReference < ActiveRecord::Base

	validates_presence_of :ref_theme, :ref_source, :source, :construction_mode

	def self.sources
		find(:all, :select => "DISTINCT source")
	end

	def self.by_source(source)
		find(:all, :conditions => {:source => source})
	end

	def self.referenced_by_theme_and_source(theme, source)
		find(:all, :conditions => ["ref_theme = ? AND source = ? AND construction_mode <> 'E'", theme, source])
	end

	def self.referenced_by_theme_and_source_fused(theme, source)
		find(:all, :conditions => {:ref_theme => theme, :source => source, :construction_mode => 'F'})
	end

	def self.referenced_by_theme_and_source_attached(theme, source)
		find(:all, :conditions => {:ref_theme => theme, :source => source, :construction_mode => 'A'})
	end

	def self.excluded_by_theme_and_source(theme, source)
		find(:all, :conditions => {:ref_theme => theme, :source => source, :construction_mode => 'E'})
	end

	def self.all_by_theme_and_source(theme, source)
		find(:all, :conditions => {:ref_theme => theme, :source => source})
	end

	def self.matched_cdu_themes(cote)
		find(:all, :conditions => ["source = 'portfoliodw' AND SUBSTRING(?, 1, LENGTH(ref_source)) = ref_source AND construction_mode <> 'E'", cote])
	end

	def self.excluded_cdu_themes(cote)
		find(:all, :conditions => ["source = 'portfoliodw' AND SUBSTRING(?, 1, LENGTH(ref_source)) = ref_source AND construction_mode = 'E'", cote])
	end

	def self.matched_bdm_themes(apkid, source)
		find(:all, :conditions => ["ref_source = ? AND source = ? AND construction_mode <> 'E'", apkid, source])
	end

	def self.excluded_bdm_themes(apkid, source)
		find(:all, :conditions => {:ref_source => apkid, :source => source, :construction_mode => 'E'})
	end

  def self.create_references(references, source, exclusions = nil)
   	nb_ref = 0
		nb_excl = 0
 
    references.each do |theme, references| 
      unless theme.nil? and references.nil?
				references.each do |ref|
	        reference = ThemesReference.new
  	      reference.ref_source = ref
    	    reference.ref_theme = theme
      	  reference.source = source
					reference.construction_mode = 'F'
        	reference.save!
					nb_ref += 1
				end
      end
    end
    
    unless exclusions.nil?
      exclusions.each do |theme, exclusions| 
        unless theme.nil? and exclusions.nil?
					exclusions.each do |excl|
	          exclusion = ThemesReference.new
  	        exclusion.ref_source = excl
    	      exclusion.ref_theme = theme
      	    exclusion.source = source
						exclusion.construction_mode = 'E'
        	  exclusion.save!
						nb_excl += 1
					end
        end
      end
    end

		puts "#{nb_ref} refererences and #{nb_excl} exclusions created! (total: #{nb_ref + nb_excl})"
  end
  
  def name_theme
    if @name_theme.blank?
      theme = Theme.find(:first, :conditions => ["reference = ?", self.ref_theme]) unless self.ref_theme.blank?
      @name_theme = theme.name_to_root unless theme.nil?
    end
    return @name_theme
  end
end
