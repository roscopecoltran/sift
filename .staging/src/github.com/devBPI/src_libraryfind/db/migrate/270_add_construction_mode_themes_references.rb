class AddConstructionModeThemesReferences < ActiveRecord::Migration
  def self.up
    add_column :themes_references, :construction_mode, :string, :default => 'F'
  end

  def self.down
		remove_column :themes_references, :construction_mode
  end
end
