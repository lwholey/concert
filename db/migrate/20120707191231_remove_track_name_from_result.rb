class RemoveTrackNameFromResult < ActiveRecord::Migration
  def self.up
    remove_column :results, :track_name
  end

  def self.down
    add_column :results, :track_name, :string
  end
end
