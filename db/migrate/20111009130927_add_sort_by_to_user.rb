class AddSortByToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :sort_by, :string
  end

  def self.down
    remove_column :users, :sort_by
  end
end
