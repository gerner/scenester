ATTEND_HOURS_BEFORE = 2
ATTEND_HOURS_AFTER = 1
QUERY_OPERATORS = ["source", "venue", "tag", "tags"]

STOP_WORDS = Set.new ["the", "of"]

def jaccard(a, b)
  atoks = Set.new(a.downcase.split()).delete_if {|o| STOP_WORDS.include? o}
  btoks = Set.new(b.downcase.split()).delete_if {|o| STOP_WORDS.include? o}
  
  atoks.intersection(btoks).size.to_f / atoks.union(btoks).size.to_f
end

class Event < ActiveRecord::Base
  cattr_reader :per_page

  @@per_page = 100

  validates_uniqueness_of :source_id, :scope => :source
  validates_presence_of :title

  belongs_to :venue
  has_many :event_sources, :dependent => :destroy

  #-------------------
  # static methods
  #-------------------

  def self.find_by_slug slug
    self.find(slug.split("-").last)
  end
  
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
    Event.joins(:event_sources).where("event_sources.source = ? AND event_sources.remote_id = ?", e.source, e.source_id)
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

  def self.search_conditions(q, options = {})
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
        op[1] = CGI::unescape(op[1].downcase)
        if(op[0] == "source")
          clauses << "events.source = ?"
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
        elsif(op[0] == "tags")
          tags_clauses = []
          op[1].split(",").each do |tag|
            tags_clauses << "(lower(tags) LIKE ? OR lower(tags) LIKE ? OR lower(tags) LIKE ? OR lower(tags) LIKE ?)"
            tag = CGI::unescape(tag.strip)
            values << "%,#{tag}%, %"
            values << "#{tag}%,%"
            values << "%,#{tag}%"
            values << "#{tag}%"
          end
          clauses << "("+tags_clauses.join("or")+")"
        end
      else
        clauses << "lower(title) LIKE ?"
        values << "%#{part.downcase}%"
      end
    end
    return [clauses.join(" AND ")]+values
  end

  #-------------------
  # instance methods
  #-------------------
  
  def safe_image
    self.image.blank? ? "/images/eventicon.png" : self.image
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

  def slug
    "#{title.gsub(/[^[:alnum:]]+/i,'-').downcase}-#{id}"
  end

  def to_param
    slug
  end

  def venue_with_address
    if venue
      "#{venue.name}, #{venue.address}"
    else
      venue_name
    end
  end

  def duration
    (self.end - start).abs
  end

  def pill_dom_id
    return "eventpill-#{id}"
  end

  def pill_content_dom_id
    return "eventpill-#{id}-content"
  end

  def share_text
    d = DateTime.now.beginning_of_day
    text = ""
    text = "Tonight: " if start.beginning_of_day == d
    text = "Tomorrow: " if start.beginning_of_day.advance(:days => -1) == d
    text += title_with_venue
    return text
  end

  def similarity_vector(candidate)
    features = {}

    features[:title_dist] = title.levenshtein_similar(candidate.title)
    features[:title_jaccard] = jaccard(title, candidate.title)
    features[:venue_exact] = venue_id == candidate.venue_id ? 1 : 0
    #venue similarity
    if venue_id == candidate.venue_id
      features[:venue_dist] = 1
      features[:venue_jaccard] = 1
    elsif venue && candidate.venue
      features[:venue_dist] = venue.name.levenshtein_similar(candidate.venue.name)
      features[:venue_jaccard] = jaccard(venue.name, candidate.venue.name)
    else
      features[:venue_dist] = 0
      features[:venue_jaccard] = 0
    end
    # url matches?
    features[:url_matches] = url == candidate.url ? 1 : 0
    # source matches?
    features[:source_matches] = source == candidate.source ? 0 : 1
    # difference squared in start times
    features[:start_se] = (start - candidate.start) ** 2.0
    features[:duration_se] = (duration - candidate.duration) ** 2.0
    
    return features
  end

  def similarity(candidate)
=begin
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
=end
    features = similarity_vector(candidate)
    -0.09648*features[:title_dist]  +  0.03553*features[:title_jaccard]  +  -0.2125*features[:venue_exact]  +  0.108*features[:venue_dist]  +  0.6245*features[:venue_jaccard]  +  -0.4022*features[:url_matches]  +  0.1921*features[:source_matches]  +  -4.946*10**-12*features[:start_se]  +  -5.616*10**-14*features[:duration_se]  +  0.00396018
  end

  def is_duplicate_of(candidate)
    #id != candidate.id && similarity(candidate) > 0.307741
    #id != candidate.id && similarity(candidate > 0.634310
    #this decision tree built by waffles
    features = similarity_vector(candidate)
    if features[:source_matches] < 1
      if features[:title_jaccard] < 0.25
        if features[:venue_jaccard] < 0.5
          return false
        else
          if features[:start_se] < 3.73248e+09
            if features[:venue_exact] < 1
              return false
            else
              return true
            end
          else
            return false
          end
        end
      else
        return false
      end
    else
      if features[:start_se] < 1.8792e+08
        if features[:venue_jaccard] < 0.333333
          if features[:title_jaccard] < 0.166667
            return false
          else
            if features[:venue_dist] < 0.201389
              if features[:title_dist] < 0.4
                return true
              else
                return false
              end
            else
              return true
            end
          end
        else
          return true
        end
      else
        return false
      end
    end
  end

  def duplicates(opts = {})
    options = {}.merge(opts)
    duplicates = []
    candidates = options[:candidates] || Event.where("id <> ? AND start > ? AND start < ?", id, start.advance(:days => -1), start.advance(:days => 1)).includes(:venue)
    candidates.each do |candidate|
      duplicates << candidate if is_duplicate_of(candidate)
    end
    return duplicates
  end

  def merge(other)
    # add the sources
    other.event_sources.each do |s|
      next if event_sources.exists(:source => s.source)
      event_sources << s.clone
    end

    title ||= other.title
    image ||= other.image
    url ||= other.url
    start ||= other.start
    self.end || other.end
    tags ||= other.tags
    venue ||= other.venue

    return self
  end

end
