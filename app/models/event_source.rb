class EventSource < ActiveRecord::Base
  validates_presence_of :remote_id, :source
  validates_uniqueness_of :source, :scope => :event_id

  belongs_to :event
end
