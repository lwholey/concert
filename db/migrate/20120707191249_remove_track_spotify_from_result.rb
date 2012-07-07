class RemoveTrackSpotifyFromResult < ActiveRecord::Migration
  def self.up
    remove_column :results, :track_spotify
  end

  def self.down
    add_column :results, :track_spotify, :string
  end
end
