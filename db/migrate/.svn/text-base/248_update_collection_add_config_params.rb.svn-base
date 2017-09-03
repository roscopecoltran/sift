class UpdateCollectionAddConfigParams < ActiveRecord::Migration
    def self.up
      add_column(:collections, :nb_result, :integer, :null => false, :default => 100)
      add_column(:collections, :timeout, :integer, :null => false, :default => 20)
      add_column(:collections, :polling_timeout, :integer, :null => false, :default => 300)
    end
    
    def self.down
      remove_column(:collections, :nb_result )
      remove_column(:collections, :timeout )
      remove_column(:collections, :polling_timeout )
    end
  end