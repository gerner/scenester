class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :image
      t.string :title
      t.string :url
      t.string :venue
      t.datetime :start
      t.datetime :end
      t.string :tags
      t.string :source

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
