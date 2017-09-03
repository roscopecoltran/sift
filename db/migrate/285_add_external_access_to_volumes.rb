class AddExternalAccessToVolumes < ActiveRecord::Migration
  def self.up
    add_column :volumes, :external_access, :boolean, :default => false
  end

  def self.down
		remove_column :volumes, :external_access
  end
end
