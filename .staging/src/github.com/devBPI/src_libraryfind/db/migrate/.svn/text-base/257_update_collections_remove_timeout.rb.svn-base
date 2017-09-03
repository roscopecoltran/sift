class UpdateCollectionsRemoveTimeout < ActiveRecord::Migration
  
  def self.up
    remove_column :collections, :timeout
    remove_column :collections, :polling_timeout

  end
  
  def self.down
    add_column :collections, :timeout, :integer
    add_column :collections, :polling_timeout, :integer
  end
  
end