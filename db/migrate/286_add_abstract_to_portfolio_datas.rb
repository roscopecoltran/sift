class AddAbstractToPortfolioDatas < ActiveRecord::Migration
  def self.up
    add_column :portfolio_datas, :abstract, :string
  end

  def self.down
		remove_column :portfolio_datas, :abstract
  end
end
