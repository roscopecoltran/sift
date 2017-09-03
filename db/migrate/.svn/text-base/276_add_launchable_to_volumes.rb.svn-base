class AddLaunchableToVolumes < ActiveRecord::Migration
  def self.up
    add_column :volumes, :launchable, :boolean, :default => 0
  end

  def self.down
		remove_column :volumes, :launchable
  end
end
