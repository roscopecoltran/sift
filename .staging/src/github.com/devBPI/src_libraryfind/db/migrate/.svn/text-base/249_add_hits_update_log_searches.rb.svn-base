class AddHitsUpdateLogSearches < ActiveRecord::Migration
    def self.up
      add_column(:log_searches, :hits, :boolean, :null => false, :default => 1)
    end
    
    def self.down
      remove_column(:log_searches, :hits)
    end
  end