ATTEND_HOURS_BEFORE = 2
ATTEND_HOURS_AFTER = 1
QUERY_OPERATORS = ["source", "venue", "tag"]

class Event < ActiveRecord::Base
  validates_uniqueness_of :source_id, :scope => :source
  validates_presence_of :title

  belongs_to :venue
  has_many :event_sources, :dependent => :destroy

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

  def self.search(q, options = {})
    #split query up into tokens
    parts = q.split
    #search over title, use tags operator to search over tags
    opts = {:clauses => [], :values => []}.merge(options)
    clauses = opts[:clauses]
    values = opts[:values]
    parts.each do |part|
      #query operator
      op = part.split(":")
      if(part.match(/[a-z]+:./) && QUERY_OPERATORS.index(op[0]))
        op[1] = CGI::unescape(op[1])
        if(op[0] == "source")
          clauses << "source = ?"
          values << op[1]
        elsif(op[0] == "venue")
          clauses << "venue_name LIKE ?"
          values << "%#{op[1]}%"
        elsif(op[0] == "tag")
          clauses << "(lower(tags) LIKE ? OR lower(tags) LIKE ? OR lower(tags) LIKE ? OR lower(tags) LIKE ?)"
          op[1] = CGI::unescape(op[1])
          values << "%,#{op[1]}, %"
          values << "#{op[1]},%"
          values << "%,#{op[1]}"
          values << op[1]
        end
      else
        clauses << "lower(title) LIKE ?"
        values << op[1]
      end
    end
    Event.where([clauses.join(" AND ")]+values)
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

  def safe_venue_name
    if venue
      venue.name
    else
      ""
    end
  end

  def title_with_venue
    if venue
      "#{title} @ #{venue.name}"
    else
      title
    end
  end

  def similarity(candidate)
    title_similarity  = title.levenshtein_similar(candidate.title)
    venue_exact = venue_id == candidate.venue_id ? 1 : 0
    #venue similarity
    if venue_id == candidate.venue_id
      venue_similarity = 1
    elsif venue && candidate.venue
      venue_similarity = venue.name.levenshtein_similar(candidate.venue.name)
    else
      venue_similarity = 0
    end
    # url matches?
    url_matches = url == candidate.url ? 1 : 0
    # source matches?
    source_matches = source == candidate.source ? 0 : 1
    # difference squared in start times
    start_diff = (start - candidate.start) ** 2.0

    1.09 * title_similarity  +  0.2619 * venue_exact  +  -0.03276 * venue_similarity  +  -0.1249 * url_matches  +  0.00764 * source_matches  +  -0.00000000001425 * start_diff  +  -0.0890041
  end

  def is_duplicate_of(candidate)
    similarity(candidate) > 0.307741
  end

  def duplicates
    duplicates = []
    candidates = Event.where("id <> ? AND start > ? AND start < ?", id, start.advance(:days => -1), start.advance(:days => 1))
    candidates.each do |candidate|
      duplicates << candidate if is_duplicate_of(candidate)
    end
    return duplicates
  end

end
