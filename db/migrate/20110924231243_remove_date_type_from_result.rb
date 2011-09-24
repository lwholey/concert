class RemoveDateTypeFromResult < ActiveRecord::Migration
  def self.up
    remove_column :results, :date_type
  end

  def self.down
    add_column :results, :date_type, :datetime
  end
end
