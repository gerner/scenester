class Venue < ActiveRecord::Base
  validates_uniqueness_of :source_id, :scope => :source
  validates_presence_of :name
  validates_presence_of :source
  validates_presence_of :source_id

  def self.find_and_merge(v)
    v_other = nil
    v_other ||= Venue.where(:source => v.source, :source_id => v.source_id).first if v.source && v.source_id
    v_other ||= Venue.where(:address => v.address, :city => v.city, :name => v.name).first if v.address && v.city && v.name
    v_other ||= Venue.where(:name => v.name).first
    v_other ||= v
    return v_other
  end

end
