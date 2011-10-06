class AddEndDateToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :end_date, :string
  end

  def self.down
    remove_column :users, :end_date
  end
end
