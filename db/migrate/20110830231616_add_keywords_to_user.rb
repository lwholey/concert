class AddKeywordsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :keywords, :string
  end

  def self.down
    remove_column :users, :keywords
  end
end
