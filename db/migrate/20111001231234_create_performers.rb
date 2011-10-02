class CreatePerformers < ActiveRecord::Migration
  def self.up
    create_table :performers do |t|
      t.string :performer
      t.string :you_tube_url

      t.timestamps
    end
  end

  def self.down
    drop_table :performers
  end
end
