class AddIdSearchToUserRecord < ActiveRecord::Migration
  def self.up
    add_column :user_records, :id_search, :string, :default => ''
  end

  def self.down
		remove_column :user_records, :id_search
  end
end
