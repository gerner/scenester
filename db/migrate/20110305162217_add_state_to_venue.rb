class AddStateToVenue < ActiveRecord::Migration
  def self.up
    add_column :venues, :state, :string
  end

  def self.down
    remove_column :venues, :state
  end
end
