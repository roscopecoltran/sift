class UpdateCollectionAddHarvestFlag < ActiveRecord::Migration
  
  def self.up
	  add_column :collections, :full_harvest, :boolean, :default => 0
  end
  
  def self.down
	  remove_column :collections, :full_harvest
  end
  
end
