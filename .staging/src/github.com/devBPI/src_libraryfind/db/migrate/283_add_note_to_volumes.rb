class AddNoteToVolumes < ActiveRecord::Migration
  def self.up
    add_column :volumes, :note, :string, :default => ''
  end

  def self.down
		remove_column :volumes, :note
  end
end
