class AddIdSearchToUserRecordList < ActiveRecord::Migration
  def self.up
    add_column :list_user_records, :id_search, :string, :default => ''
  end

  def self.down
		remove_column :list_user_records, :id_search
  end
end
