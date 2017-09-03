class AddFusionFieldMappingTheme < ActiveRecord::Migration
  def self.up
    add_column :themes_references, :fusion, :boolean, :default => 1
  end

  def self.down
    remove_column :themes_references, :fusion
  end
end
