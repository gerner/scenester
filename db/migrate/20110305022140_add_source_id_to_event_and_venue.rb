class AddSourceIdToEventAndVenue < ActiveRecord::Migration
  def self.up
    add_column :events, :source_id, :string
    add_column :venues, :source, :string
    add_column :venues, :source_id, :string
  end

  def self.down
    remove_column :events, :source_id
    remove_column :venues, :source
    remove_column :venues, :source_id
  end
end
