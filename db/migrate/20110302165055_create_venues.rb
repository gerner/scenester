class CreateVenues < ActiveRecord::Migration
  def self.up
    create_table :venues do |t|
      t.string :name
      t.string :address
      t.string :phone
      t.float :lat
      t.float :long
      t.string :url
      t.string :map_url

      t.timestamps
    end
  end

  def self.down
    drop_table :venues
  end
end
