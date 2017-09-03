class UpdateHistorySearchesAddJobIds < ActiveRecord::Migration
    def self.up
      add_column(:history_searches, :job_ids, :text, :null => true)
    end
    
    def self.down
      remove_column(:history_searches, :job_ids)
    end
  end