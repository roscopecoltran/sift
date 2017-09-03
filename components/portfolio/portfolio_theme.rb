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
class PortfolioTheme
  def initialize(cnx, logger = nil)
    restart
    @conn = cnx
    @logger = logger
    @select_libelle_time = 0
    @match_reference_time = 0
    @theme_name_concat_time = 0
    @array_themes_time = 0
    @records_count = 0
  end
    
  def restart
    @error = 0
    @indiceNotMatched = Array.new
    @matched = 0
  end
  
  def errors
    return @error
  end
  
  def matched
    return @matched
  end
  
  def indices_no_match
    return @indiceNotMatched
  end

	# Theme is built by looking for mapping using each bdm theme apkid (starting at the end)
	# If mapping is found, n1 & n2 themes are built and the rest of the bdm themes arborescence is concatenated to the n1 & n2 shared themes
	def translateBdmThemes(multi_themes, multi_labels, source)
		lf_themes = Array.new
		multi_themes = multi_themes.split("@;@")
		multi_labels = multi_labels.split("@;@")
		begin		
			multi_themes.each_with_index do |themes, i|
				themes = themes.split(" > ").reverse
				labels = multi_labels[i].split(" > ").reverse
				j = 0
				references = ""
				while references.empty? && j <= themes.length && !themes[j].nil?
					references = ThemesReference.matched_bdm_themes(themes[j].strip, source) 
					excluded_themes = ThemesReference.excluded_bdm_themes(themes[j].strip, source)
					references.reject! {|ref| excluded_themes.include?(ref)} unless excluded_themes.nil?
					if !references.empty?
						references.each do |ref|
							idx = ref.construction_mode == 'F' ? j - 1 : j 
							label = labels[0..idx].reverse.join(" > ") unless idx < 0  
							lf_theme =  ref.name_theme
							lf_theme += THEME_SEPARATOR + label unless label.nil? or lf_theme.nil?
							lf_theme = lf_theme.split(" > ").collect {|th| th.capitalize}.join(" > ")
							lf_themes << lf_theme unless lf_themes.include?(lf_theme) or lf_theme.nil? 
						end
					else
          	if @indiceNotMatched.include?(themes[j])
            	@matched += 1
          	else
            	@indiceNotMatched << themes[j] if @indiceNotMatched.size < 1000
            	@error += 1
          	end
					end
					j += 1
				end
			end
    rescue => e
      unless @logger.nil?
        @logger.error("[BDM themes] error : #{e.message}")
        @logger.error("[BDM themes] trace : #{e.backtrace.join("\n")}")
      end
    end
		lf_themes = lf_themes.join(";")
		return lf_themes
	end
  
	# Mapping for the cdus are done with the indice of the notice (indice = ref_source).
	# If mapping is found, lf themes are built (n1&n2)
	# Then the label corresponding to the indice is concatenated with n1&n2 lf shared themes
  def translateCduThemes(themes)
    @records_count += 1
    lf_themes = Array.new
    begin
      themes.split("@;@").each do |theme|
        theme = theme.strip.gsub(/'/,"")
        query = "select libelle from dw_authorityindices where indice = '#{theme}'" 
        r = @conn.select_one(query)
        label = r['libelle'] if r
        references = ThemesReference.matched_cdu_themes(theme.strip)
				exclusions = ThemesReference.excluded_cdu_themes(theme.strip).collect! {|excl| excl.ref_theme}
				references.reject! {|ref| exclusions.include? ref.ref_theme}

        if !references.nil? and !references.empty?
          references.each do |ref|
            lf_theme = ref.name_theme
            unless label.nil? or lf_theme.nil?
              lf_theme += THEME_SEPARATOR + label
            end
            
            unless lf_theme.nil? 
							lf_theme = lf_theme.split(" > ").collect {|th| th.capitalize}.join(" > ")
							lf_themes << lf_theme unless lf_themes.include?(lf_theme)
            end
          end
        else
          if @indiceNotMatched.include?(theme)
            @matched += 1
          else
            @indiceNotMatched << theme if @indiceNotMatched.size < 1000
            @error += 1
          end
        end
      end
    rescue => e
      unless @logger.nil?
        @logger.error("[translateTheme] error : #{e.message}")
        @logger.error("[translateTheme] trace : #{e.backtrace.join("\n")}")
      end
    end
		return lf_themes.join(";")
  end
  
  def getCDU(indices)
      return "" if indices.blank?
      label = ""
      begin
        label = Array.new
        indices.split("@;@").each do |indice|
          #POUR 10.1.2.8 
					#indice = indice.strip.gsub(/[']/, '\\\\\'')
					#POUR 10.1.2.100
					indice = indice.strip.gsub(/[']/, '\'\'')
          query = "select libelle from dw_authorityindices where indice = '#{indice}'"
          r = @conn.select_one(query)
          if r
            label << r['libelle']
          else
            label << " "
          end
        end
				return "@;@#{label.join("@;@")}"
      rescue => e
        unless @logger.nil?
          @logger.error("[getCDU] error : #{e.message}")
          @logger.error("[getCDU] trace : #{e.backtrace.join("\n")}")
        end
      end
    end

end
