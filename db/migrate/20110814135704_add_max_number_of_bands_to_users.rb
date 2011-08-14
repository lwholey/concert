class AddMaxNumberOfBandsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :maxNumberOfBands, :string
  end

  def self.down
    remove_column :users, :maxNumberOfBands
  end
end
