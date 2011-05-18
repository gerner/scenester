class EventRecommended < ActiveRecord::Migration
  def self.up
    add_column :events, :recommended, :boolean
    add_column :events, :description, :text
  end

  def self.down
    remove_column :events, :recommended
    remove_column :events, :description
  end
end
