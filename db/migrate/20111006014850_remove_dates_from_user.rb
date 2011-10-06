class RemoveDatesFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :dates
  end

  def self.down
    add_column :users, :dates, :string
  end
end
