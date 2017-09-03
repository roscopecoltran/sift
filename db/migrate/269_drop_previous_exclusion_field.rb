class DropPreviousExclusionField < ActiveRecord::Migration
  def self.up
		remove_column :themes_references, :exclusion
		rename_column :themes_references, :exclusions, :exclusion
  end

  def self.down
		rename_column :themes_references, :exclusion, :exclusions
    add_column :themes_references, :exclusion, :string
  end
end
