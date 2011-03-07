ATTEND_HOURS_BEFORE = 2
ATTEND_HOURS_AFTER = 1

class Event < ActiveRecord::Base
  validates_uniqueness_of :source_id, :scope => :source
  validates_presence_of :title

  belongs_to :venue

  #-------------------
  # static methods
  #-------------------
  
  def self.to_ics(events)
    cal = Icalendar::Calendar.new
    events.each do |e|
      cal.event do
        dtstart e.start.to_datetime
        dtend [e.end, e.start.advance(:hours => 2)].max.to_datetime
        summary e.title
        description "#{e.source}: #{e.url}\n#{e.tags}"
        location e.venue_name
      end
    end
    cal.to_ical
  end

  def self.find_matching(e)
    #TODO: what if an event has no url and has just changed time? how to differentiate this from events that recur (same title, different event)
    #Event.where("(title = ? AND start = ?) OR (url = ?)", e.title, e.start, e.url)
    Event.where(:source => e.source, :source_id => e.source_id)
  end

  def self.find_attending(venue_name, t, options = {})
    options = {:hours_before => 2, :hours_after => 1}.merge(options)
    #TODO: need to do a fuzzier match on the venue
    Event.where("venue_name = ? AND start < ? AND end > ?", venue_name, t.advance(:hours => options[:hours_before]), t.advance(:hours => -options[:hours_after]))
  end

  def self.find_attending_any(vtimes, options = {})
    options = {:hours_before => 2, :hours_after => 1}.merge(options)
    #TODO: need to do a fuzzier match on the venue
    
    whereValues = []
    vtimes.each do |v|
      whereValues << v[:venue]
      whereValues << v[:time].advance(:hours => options[:hours_before])
      whereValues << v[:time].advance(:hours => -options[:hours_after])
    end
    whereClause = (["(venue_name = ? AND start < ? AND end > ?)"] * vtimes.size).join(" OR ")

    Event.where([whereClause] + whereValues)
  end

  #-------------------
  # instance methods
  #-------------------
  
  def safe_image
    self.image.blank? ? "/images/seattlelogoinverse.png" : self.image
  end

  def tonight?
    (self.start - Time.now).abs < 86400
  end

  def title_with_venue
    if venue
      "#{title} @ #{venue.name}"
    else
      title
    end
  end
end
