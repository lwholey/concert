class AddDatesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :dates, :string
  end

  def self.down
    remove_column :users, :dates
  end
end
