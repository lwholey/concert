class DropPerformersTable < ActiveRecord::Migration
  def self.up
    drop_table :performers
  end

  def self.down
  end
end
