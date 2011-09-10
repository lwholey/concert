class AddUserId < ActiveRecord::Migration
  def self.up
    add_column :results, :user_id, :integer
    add_index :results, :user_id
  end

  def self.down
    remove_column :results, :user_id
    remove_index :results, :user_id
  end
end
