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

class Theme < ActiveRecord::Base

  validates_presence_of :reference, :label 
	validates_uniqueness_of :reference
	validates_length_of :reference, :maximum => 10

	def self.roots
		find(:all, :conditions => ["parent = 0"], :order => "reference asc")
	end

	def self.find_by_reference(ref)
		find(:first, :conditions => {:reference => ref})
	end

	def children
		Theme.find(:all, :conditions => ["parent = ?", self.reference.to_i])
	end

	def full_name
		"#{self.reference} - #{self.label}"
	end
  
  def name_to_root
		@name_to_root = @name_to_root.blank? ? calculate_theme : @name_to_root
    return @name_to_root
  end
  
  def calculate_theme
		theme = self.label
		unless self.parent.nil? or self.parent.to_i == 0
			t = Theme.find(:first, :conditions => ["reference = ?", self.parent.to_i])
			theme = [t.calculate_theme, THEME_SEPARATOR, theme].join()
		end
		return theme
	end
end
