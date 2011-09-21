class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.string :name
      t.string :date_string
      t.datetime :date_type
      t.string :venue
      t.string :band
      t.string :track_name
      t.string :track_spotify
      t.string :details_url

      t.timestamps
    end
  end

  def self.down
    drop_table :results
  end
end
