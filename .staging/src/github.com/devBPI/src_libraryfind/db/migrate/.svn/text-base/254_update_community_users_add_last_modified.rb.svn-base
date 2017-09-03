class UpdateCommunityUsersAddLastModified < ActiveRecord::Migration
  
  def self.up
	  add_column :community_users, :last_modified, :datetime, :default => Time.now
  end
  
  def self.down
	  remove_column :community_users, :last_modified
  end
  
end