class RemoveOldFieldsThemesReferences < ActiveRecord::Migration
  def self.up
		remove_column :themes_references, :exclusion
		remove_column :themes_references, :fusion
  end

  def self.down
    add_column :themes_references, :exclusion, :default => false
    add_column :themes_references, :fusion, :default => true
  end
end
