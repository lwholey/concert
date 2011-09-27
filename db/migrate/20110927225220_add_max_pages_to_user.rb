class AddMaxPagesToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :max_pages, :integer
  end

  def self.down
    remove_column :users, :max_pages
  end
end
