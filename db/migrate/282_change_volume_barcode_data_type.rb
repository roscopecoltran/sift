class ChangeVolumeBarcodeDataType < ActiveRecord::Migration
  def self.up
		change_column :volumes, :barcode, :string
  end

  def self.down
		change_column :volumes, :barcode, :integer
  end
end
