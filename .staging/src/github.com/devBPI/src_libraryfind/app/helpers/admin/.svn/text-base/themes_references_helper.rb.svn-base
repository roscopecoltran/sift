module Admin::ThemesReferencesHelper

	def list_all_themes
		themes = Theme.all.collect {|th| [th.full_name, th.reference.to_s]}
		themes << ['-- Choisir un thème --', '0']
		themes = themes.sort_by {|th| th[1]}
		return themes
	end

	def list_themes_by_source(source)
		ThemesReference.by_source(source).collect {|ref| ref.ref_theme}.compact.uniq.sort
	end

	def list_all_sources
		return ThemesReference.sources.collect {|s| s.source}.compact
	end

	def normalize_references(references)
		references.collect {|ref| ref.ref_source.gsub(" ", "[espace]")}.join(" / ")
	end

end
