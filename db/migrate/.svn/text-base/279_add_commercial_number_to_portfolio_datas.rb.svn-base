class AddCommercialNumberToPortfolioDatas < ActiveRecord::Migration
  def self.up
    add_column :portfolio_datas, :commercial_number, :string, :default => ''
  end

  def self.down
		remove_column :portfolio_datas, :commercial_number
  end
end
