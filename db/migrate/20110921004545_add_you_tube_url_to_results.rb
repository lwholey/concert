class AddYouTubeUrlToResults < ActiveRecord::Migration
  def self.up
    add_column :results, :you_tube_url, :string
  end

  def self.down
    remove_column :results, :you_tube_url
  end
end
