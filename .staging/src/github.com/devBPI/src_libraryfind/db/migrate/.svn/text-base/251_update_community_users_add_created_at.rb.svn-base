class UpdateCommunityUsersAddCreatedAt < ActiveRecord::Migration
  
  def self.up
	  add_column :community_users, :created_at, :datetime, :default => Time.now
  end
  
  def self.down
	  remove_column :community_users, :created_at
  end
  
end