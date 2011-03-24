class PopulateEventSourceFromEvents < ActiveRecord::Migration
  def self.up
    Event.all.each do |event|
      event_source = event.event_sources.build(:source => event.source, :remote_id => event.source_id, :url => event.url)
      event_source.save
    end
  end

  def self.down
    #we won't back this out...
  end
end
