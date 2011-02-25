ATTEND_HOURS_BEFORE = 2
ATTEND_HOURS_AFTER = 1

class Event < ActiveRecord::Base
  def self.to_ics(events)
    cal = Icalendar::Calendar.new
    events.each do |e|
      cal.event do
        dtstart e.start.to_datetime
        dtend [e.end, e.start.advance(:hours => 2)].max.to_datetime
        summary e.title
        description "#{e.source}: #{e.url}\n#{e.tags}"
        location e.venue
      end
    end
    cal.to_ical
  end

  def self.find_matching(e)
    #TODO: what if an event has no url and has just changed time? how to differentiate this from events that recur (same title, different event)
    Event.where("(title = ? AND start = ?) OR (url = ?)", e.title, e.start, e.url)
  end

  def self.find_attending(venue, t, options = {})
    options = {:hours_before => 2, :hours_after => 1}.merge(options)
    #TODO: need to do a fuzzier match on the venue
    Event.where("venue = ? AND start < ? AND end > ?", venue, t.advance(:hours => options[:hours_before]), t.advance(:hours => -options[:hours_after]))
  end
end
