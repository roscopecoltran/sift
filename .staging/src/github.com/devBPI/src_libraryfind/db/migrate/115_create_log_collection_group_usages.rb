class CreateLogCollectionGroupUsages < ActiveRecord::Migration
  def self.up
    create_table :log_collection_group_usages do |t|
      t.string :idSets
      t.timestamps
    end
  end

  def self.down
    drop_table :log_collection_group_usages
  end
end
