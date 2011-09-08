class AddPageNumberToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :pageNumber, :integer
  end

  def self.down
    remove_column :users, :pageNumber
  end
end
