class UpdateLogSearchesAddFieldLogAction < ActiveRecord::Migration
  def self.up
    add_column :log_searches, :log_action, :string, :default => ""
  end

  def self.down
    remove_column :log_searches, :log_action
  end
end
