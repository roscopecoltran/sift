class AddDescriptionToParameters < ActiveRecord::Migration
  def self.up
    add_column :parameters, :description, :string
    add_column :parameters, :editable, :boolean, :default => 0
  end

  def self.down
		remove_column :parameters, :description
		remove_column :parameters, :editable
  end
end
