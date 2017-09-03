class CreateLogDoc < ActiveRecord::Migration
  def self.up
    create_table :log_docs do |t|
      t.column :id_doc, :string
      t.column :title_doc, :string
      t.column :status, :boolean, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :log_docs
  end
end