class RemoveMaxNumberOfBandsFromUser < ActiveRecord::Migration
  def self.up
    remove_column :users, :maxNumberOfBands
  end

  def self.down
    add_column :users, :maxNumberOfBands, :string
  end
end
