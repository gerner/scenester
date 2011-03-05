class AddVenueAddressInfo < ActiveRecord::Migration
  def self.up
    add_column :venues, :city, :string
    add_column :venues, :zipcode, :string
  end

  def self.down
    remove_column :venues, :city
    remove_column :venues, :zipcode
  end
end
