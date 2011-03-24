class CreateEventSources < ActiveRecord::Migration
  def self.up
    create_table :event_sources do |t|
      t.references :event
      t.string :source
      t.string :remote_id
      t.string :url

      t.timestamps
    end
  end

  def self.down
    drop_table :event_sources
  end
end
