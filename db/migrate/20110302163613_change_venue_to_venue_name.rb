class ChangeVenueToVenueName < ActiveRecord::Migration
  def self.up
    rename_column :events, :venue, :venue_name
  end

  def self.down
    rename_column :events, :venue_name, :venue
  end
end
