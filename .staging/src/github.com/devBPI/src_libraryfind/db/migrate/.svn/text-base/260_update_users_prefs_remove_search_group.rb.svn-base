class UpdateUsersPrefsRemoveSearchGroup < ActiveRecord::Migration
  
  def self.up
    remove_column :users_tabs_searches_preferences, :search_group
  end
  
  def self.down
    add_column :users_tabs_searches_preferences, :search_group, :string
  end
  
end