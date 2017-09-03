class AddExclusionFieldThemesReferences < ActiveRecord::Migration
  def self.up
    add_column :themes_references, :exclusions, :boolean, :default => 0
  end

  def self.down
    remove_column :themes_references, :exclusions
  end
end
