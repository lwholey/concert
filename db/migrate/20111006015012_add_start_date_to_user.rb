class AddStartDateToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :start_date, :string
  end

  def self.down
    remove_column :users, :start_date
  end
end
