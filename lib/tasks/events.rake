require 'net/http'
require 'uri'
require 'time'
require 'json'
require 'iconv'

require 'rubygems'
require 'rmeetup'
require 'xml'

namespace :events do
  
  desc "print events"
  task :print => :environment do
    events = Event.order("start").all
    events.each do |e|
      puts "#{e.inspect}"
    end
    puts "#{events.size} events in database"
  end

  desc "get all events"
  task :events => [:eventbrite, :brownpapertickets, :seattlerep, :fifthave, :seattleweekly, :kexp] do
  end

  desc "get eventbrite events coming soon"
  task :eventbrite => :environment do
    puts "getting eventbrite events..."
    page_number = 1
    more_events = true
    events_saved = 0
    events_found = 0
    while more_events 
      res = Net::HTTP.get(URI.parse("http://www.eventbrite.com/json/event_search?app_key=ZGI0YzliZjIzMTkx&city=Seattle&max=100&page=#{page_number}"))
      results = JSON.parse(res)
      break unless results["events"] && results["events"].size > 1
      page_number += 1
      results["events"][1..results["events"].size-1].each do |event|
        event = event["event"]
        events_found += 1
        e = Event.new
        e.image = event["logo"]
        e.title = event["title"]
        e.url = event["url"]
        e.venue_name = event["venue"]["name"]

        v = Venue.new
        v.address = event["venue"]["address"]
        v.city = event["venue"]["city"]
        v.state = event["venue"]["region"]
        v.zipcode = event["venue"]["postal_code"]
        v.lat = event["venue"]["latitude"]
        v.long = event["venue"]["longitude"]
        v.name = event["venue"]["name"]
        v.source = "eventbrite"
        v.source_id = event["venue"]["id"].to_s
        v = Venue.find_and_merge(v)
        e.venue = v if v.save

        e.start = Time.parse(event["start_date"])
        e.end = Time.parse(event["end_date"])
        e.tags = (event["category"] + ", " + event["tags"])[0..254]
        e.source = "eventbrite"
        e.source_id = event["id"].to_s
        unless Event.find_matching(e).count > 0
          puts "saving #{e.title} at #{e.start}"
          e.save!
          events_saved += 1
        end
      end
    end
    puts "#{events_found} events in Seattle from eventbrite (#{events_saved} new)"
  end

  desc "get meetup events coming soon"
  task :meetup => :environment do
    puts "getting meetup events..."
    events_found = 0
    events_saved = 0
    RMeetup::Client.api_key = "18d6110753a7a870dd59eb4919"

    results = RMeetup::Client.fetch(:events,{:zip => "98116"})

    group_ids = (results.collect { |event| event.group_id } ).join(",")
    
    group_results = RMeetup::Client.fetch(:groups, {:id => group_ids})
    groups = {}
    group_results.each do |group|
      groups[group.id.to_s] = group
    end

    results.each do |event|
      events_found += 1
      e = Event.new
      e.image = event.group_photo_url || event.photo_url
      e.title = Iconv.conv('utf-8', 'iso-8859-1', event.group_name + ":" + event.name)
      e.url = event.event_url
      e.venue_name = Iconv.conv('utf-8', 'iso-8859-1', event.venue_name)

      v = Venue.new
      v.source = "meetup"
      v.source_id = event.venue_id.to_s
      v.name = event.venue_name
      v.phone = event.venue_phone
      v.lat = event.venue_lat
      v.long = event.venue_lon
      v.city = event.venue_city
      v.zipcode = event.venue_zip
      v.address = "#{event.venue_address1} #{event.venue_address2}".strip
      v.state = event.venue_state
      v = Venue.find_and_merge(v)
      v.save!
      e.venue = v

      e.start = event.time
      e.end = event.time
      e.source = "meetup"
      e.source_id = event.id.to_s
      group = groups[event.group_id]
      topics = group.topics.collect { |t| t["name"]}
      e.tags = Iconv.conv('utf-8', 'iso-8859-1', topics.join(","))[0..254]
      unless Event.find_matching(e).count > 0
        puts "#{e.title} at #{e.start}"
        e.save!
        events_saved += 1
      end
    end
    puts "#{events_found} events in Seattle from meetup (#{events_saved} new)"
  end

=begin
  desc "get brown paper tickets events"
  task :brownpapertickets => :environment do
    puts "getting brownpaperticket events..."
    events_found = 0
    events_saved = 0
    bpt = File.read('/home/nick/downloads/bpt.json')
    results = JSON.parse(bpt)
    i=0;
    results.each do |event|
      next unless event
      next unless event["dates"][0]
      next unless event["e_city"].strip.downcase == "seattle" && event["dates"][0]["start_date"].index("2011-02-1")
      events_found += 1
      e = Event.new
      e.image = ""
      e.title = event["e_name"]
      e.url = event["e_web"]
      e.venue_name = event["e_venue"]
      e.start = Time.parse(event["dates"][0]["start_date"])
      e.end = Time.parse(event["dates"][0]["end_date"])
      e.source = "brownpapertickets"
      e.tags = event["category"]
      unless Event.find_matching(e).count > 0
        puts "saving #{e.title} at #{e.start}"
        e.save!
        events_saved += 1
      end
      
    end
    puts "#{events_found} events in Seattle from brownpapertickets (#{events_saved} new)"
  end
=end
  
  desc "get brown paper tickets events"
  task :brownpapertickets => :environment do
    puts "getting brownpaperticket events..."
    events_found = 0
    events_saved = 0
    res = Net::HTTP.get(URI.parse("http://www.brownpapertickets.com/eventfeed/91"))
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse

    nodes = d.find('/html/body/bpt/event')
    nodes.each do |n|
      events_found += 1
      e = Event.new
      e.image = ""
      e.title = n.find_first("e_name").content.strip
      e.url = n.find_first("e_web").content.strip
      e.venue_name = n.find_first("e_venue").content.strip

      v = Venue.new
      v.name = n.find_first("e_venue").content.strip
      v.address = n.find_first("e_address").content.strip
      v.city = n.find_first("e_city").content.strip
      v.state = n.find_first("e_state").content.strip
      v.zipcode = n.find_first("e_zip").content.strip
      v.phone = n.find_first("e_phone").content.strip
      v.source = "brownpapertickets"
      v.source_id = "#{v.name} #{v.address} #{v.city}, #{v.state} #{v.zipcode}"
      v = Venue.find_and_merge(v)
      e.venue = v if v.save

      e.start = Time.parse(n.find_first("start_date").content)
      e.end = Time.parse(n.find_first("end_date").content)
      e.source = "brownpapertickets"
      e.source_id = n.find_first("e_id").content.strip
      e.tags = n.find_first("category").content.strip
      unless Event.find_matching(e).count > 0
        puts "saving #{e.title} at #{e.start}"
        e.save!
        events_saved += 1
      end
      
    end
    puts "#{events_found} events in Seattle from brownpapertickets (#{events_saved} new)"
  end

  desc "get Seattle Rep Events"
  task :seattlerep => :environment do
    puts "getting seattlerep events..."
    #scrape http://www.seattlerep.org/Plays/Calendar/
    Time.zone = "Pacific Time (US & Canada)"
    baseDate = Time.now
    venue = "Seattle Repertory Theatre"
    res = Net::HTTP.get(URI.parse("http://www.seattlerep.org/Plays/Calendar/"))
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse

    #first we need to get all the plays that are showing (to get links)
    plays = {}
    nodes = d.find("id('nav')/li/ul/li/ul/li/a").each do |n|
      plays[n.children.first.to_s] = "http://www.seattlerep.org"+n.attributes["href"]
    end
        
    v = Venue.new
    v.name = "Seattle Repertory Theater"
    v.address = "155 Mercer Street"
    v.city = "Seattle"
    v.state = "WA"
    v.zipcode = "98109-4639"
    v.phone = "(206) 443-2210"
    v.lat = 47.624820
    v.long = -122.353938
    v.source = "seattlerep"
    v.source_id = "0"
    v = Venue.find_and_merge(v)
    v.save!

    #then we need to get all the showings
    events_found = 0
    events_saved = 0
    nodes = d.find("id('calendarMonth')/tr/td[@class!='otherMonth']").each do |n|
      #get the label which tells us the day
      day = n.find_first("label").first.to_s.to_i
      baseDate = Time.local(baseDate.year, baseDate.month, day)
      #get each div that is not class "iconDesc"
      n.find("div/a").each do |show|
        next if show.parent.attributes['class'] && show.parent.attributes['class'] == 'iconDesc'
        events_found += 1
        #inside that is the title of the event followed by a <br /> element followed by the time (e.g. 2:00 PM 7:30 PM)
        t = Time.parse(show.content)
        t = Time.local(baseDate.year, baseDate.month, baseDate.day, t.hour, t.min)
        e = Event.new
        e.image = ""
        e.title = show.children[0].to_s
        e.url = plays[e.title] || show.attributes["href"]
        e.venue_name = venue

        e.venue = v

        e.start = t
        e.end = t.advance(:hours => 2)
        e.source = "seattlerep"
        #TODO: need a better scheme for seattlerep source ids
        e.source_id = e.url + "|" + t.to_s
        e.tags = "Performing Arts"
        unless Event.find_matching(e).count > 0
          puts "saving #{e.title} at #{e.start}"
          e.save!
          events_saved += 1
        end
      end
    end
    puts "#{events_found} events in Seattle from seattlerep (#{events_saved} new)"
  end
  
  desc "get 5th Ave Theater Events"
  task :fifthave => :environment do
    puts "getting fifthave events..."
    #scrape http://www.seattlerep.org/Plays/Calendar/
    Time.zone = "Pacific Time (US & Canada)"
    baseDate = Time.now
    venue = "5th Avenue Theater"
    v = Venue.new
    v.name = "5th Avenue Theater"
    v.address = "1308 5th Avenue"
    v.city = "Seattle"
    v.state = "WA"
    v.zipcode = "98101-2602"
    v.phone = "(206) 625-1900"
    v.lat = 47.608910
    v.long = -122.333710
    v.source = "fifthave"
    v.source_id = "0"
    v = Venue.find_and_merge(v)
    v.save!

    #first we need to get the plays that are showing
    res = Net::HTTP.get(URI.parse("http://www.5thavenue.org/show/"))
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse

    plays = {}
    nodes = d.find("id('sidenav')/ul/li/ul/li/a").each do |n|
      plays[n.children.first.to_s] = "http://www.5thavenue.org"+n.attributes["href"]
    end

    #then we need to get all the showing
    res = Net::HTTP.get(URI.parse("http://www.5thavenue.org/calendar/"))
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse

    events_found = 0
    events_saved = 0
    nodes = d.find("id('calendarMonth')/tr/td[@class!='otherMonth']/dl").each do |n|
      #get the label which tells us the day
      day = n.find_first("dt").first.to_s.to_i
      baseDate = Time.local(baseDate.year, baseDate.month, day)
      #get each div that is not class "iconDesc"
      n.find("dd/a[not(@class)]").each do |show|
        events_found += 1
        #inside that is the title of the event followed by a <br /> element followed by the time (e.g. 2:00 PM 7:30 PM)
        t = Time.parse(show.children[0].to_s)
        t = Time.local(baseDate.year, baseDate.month, baseDate.day, t.hour, t.min)
        e = Event.new
        e.image = ""
        e.title = show.children[2].inner_xml.to_s
        e.url = plays[e.title] || show.attributes["href"]
        e.venue_name = venue
        e.venue
        e.start = t
        e.end = t
        e.source = "fifthave"
        #TODO: need a better scheme for fifthave source ids
        e.source_id = e.url + t.to_s
        e.tags = "Performing Arts"
        unless Event.find_matching(e).count > 0
          puts "saving #{e.title} at #{e.start}"
          e.save!
          events_saved += 1
        end
      end
    end
    puts "#{events_found} events in Seattle from fifthave (#{events_saved} new)"
  end

  desc "get events from Seattle Weekly"
  task :seattleweekly => :environment do
    puts "getting seattleweekly events..."
    events_skipped = 0
    events_found = 0
    events_saved = 0
    Time.zone = "Pacific Time (US & Canada)"
    t = Time.now
    #res = Net::HTTP.get(URI.parse("http://www.seattleweekly.com/events/search/category:%5B293276%5D/date:#{t.year}-#{t.month}-#{t.day}/perPage:100/"))
    res = Net::HTTP.get(URI.parse("http://www.seattleweekly.com/events/search/date:#{t.year}-#{t.month}-#{t.day}/perPage:500/"))
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse
    nodes = d.find("//div[@class='widget']//table/tr/td[@class='upper']")
    nodes.each do |n|
      e = Event.new
      e.image = ""
      e.title = n.find_first("h3/a").children[0].to_s.strip
      e.url = "http://www.seattleweekly.com"+n.find_first("h3/a").attributes["href"]
      e.venue_name = n.find_first("h4/a").children.first.to_s.strip
      e.source = "seattleweekly"
      #TODO: need a better source id for seattle weekly events
      #
      eS = Time.new(t.year, t.month, t.day, 10, 0, 0)
      eE = eS.advance(:hours => 2)
      #TODO: do we really want to skip all daily events?
      if n.find_first("h4").children[2].to_s.index("Daily")
        events_skipped += 1
        next
      end

      vnode = n.find_first("h4/a")
      v = Venue.where(:source => "seattleweekly", :source_id => vnode.attributes["href"]).first
      unless v
        vres = Net::HTTP.get(URI.parse("http://www.seattleweekly.com"+vnode.attributes["href"]))
        vp = XML::HTMLParser.string(vres, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
        vd = vp.parse
        vcard = vd.find_first("//div[@class='vcard']")

        v = Venue.new
        v.name = vcard.find_first("h1/a").content.strip
        v.source = "seattleweekly"
        v.source_id = vnode.attributes["href"]
        v.address = vcard.find_first("div[@class='address']/span[@class='adr']/span[@class='street-address']").content.strip
        v.city = vcard.find_first("div[@class='address']/span[@class='adr']/span[@class='locality']").content.strip
        v.state = vcard.find_first("div[@class='address']/span[@class='adr']/span[@class='region']").content.strip
        v.zipcode = vcard.find_first("div[@class='address']/span[@class='adr']/span[@class='postal-code']").content.strip
        v.phone = vcard.find_first("div[@class='address']/span[@class='tel']").content.strip
        v.lat = vcard.find_first("span[@class='geo']/span[@class='latitude']/span").attributes["title"].strip.to_f
        v.lat = vcard.find_first("span[@class='geo']/span[@class='longitude']/span").attributes["title"].strip.to_f
        v.url = "http://www.seattleweekly.com"+vnode.attributes["href"] 
        v = Venue.find_and_merge(v)
        v.save!
      end
      e.venue = v

      events_found += 1
      begin
        timeStrs = n.find_first("h4").children[2].to_s.split(" ").last.split("-")
        t2 = Time.parse(timeStrs[0])
        eS = Time.new(t.year, t.month, t.day, t2.hour, t2.min, 0)
        eE = eS.advance(:hours => 2)
        if(timeStrs.size > 1)
          t2 = Time.parse(timeStrs[1])
          eE = Time.new(t.year, t.month, t.day, t2.hour, t2.min)
        end
      rescue ArgumentError => exception
      end
      e.source_id = e.url + eS.to_s
      e.start = eS
      e.end = eE
      tagNodes = n.parent.next.find("td[@class='grid_hdr second']/a")
      tagNodes = n.parent.next.next.find("td[@class='grid_hdr second']/a") unless tagNodes.size > 0
      tags = []
      tagNodes.each do |tag|
        tags << tag.first.to_s.strip
      end
      e.tags = tags.join(", ")[0..254]
      unless Event.find_matching(e).count > 0
        puts "saving #{e.title} at #{e.start}"
        e.save!
        events_saved += 1
      end
    end
    puts "#{events_found} events in Seattle from seattleweekly (#{events_saved} new, #{events_skipped} skipped)"
  end

  desc "get events from KEXP"
  task :kexp => :environment do
    puts "getting kexp events..."
    events_skipped = 0
    events_found = 0
    events_saved = 0
    Time.zone = "Pacific Time (US & Canada)"
    t = Time.now
    res = Net::HTTP.get(URI.parse("http://www.kexp.org/events/clubcalendar.asp?count=0"))
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse
    nodes = d.find("/html/body/table/tr/td/table/tr/td/table/tr/td/table")[1].find("tr")
    #find("td")[1].content.strip.split(",").collect { |s| s.gsub(/\([^)]*\)/, "").strip }
    nodes.each do |n|
      events_found += 1
      parts = n.find("td")
      bands = parts[1].content.strip
      e = Event.new
      e.image = ""
      e.title = bands
      e.url = "http://www.kexp.org/events/"+parts[0].find_first("a").attributes["href"]
      e.venue_name = parts[0].content.strip.titlecase

      source_id = CGI::parse(URI.parse(parts[0].find_first("a").attributes["href"]).query)["ClubID"]
     
      v = Venue.where(:source => "kexp", :source_id => source_id).first
      unless v
        vs = Venue.where(:name => e.venue_name)
        if(vs.count == 1)
          v = vs.first
        else
          vres = Net::HTTP.get(URI.parse(e.url))
          vp = XML::HTMLParser.string(vres, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
          vd = vp.parse
          vcard = vd.find_first("//div[@class='vcard']")
          
          v = Venue.new
          v.name = e.venue_name
          v.address = vd.find_first("//span[@class='header']").parent.children[3].content.strip
          v.city = "Seattle"
          v.state = "WA"
          v.phone = vd.find_first("//span[@class='header']").parent.children[5].content.strip
          v.url = e.url
          v.source = "kexp"
          v.source_id = source_id

          v = Venue.find_and_merge(v)
          v.save!
        end
      end

      e.venue = v
      e.source = "kexp"
      e.start = Time.new(t.year, t.month, t.day, 19, 0, 0)
      #TODO: need a better scheme for kexp source ids
      e.source_id = e.url + e.start.to_s
      e.end = e.start.advance(:hours => 4)
      e.tags = "music"
      unless Event.find_matching(e).count > 0
        puts "saving #{e.title} at #{e.start}"
        e.save!
        events_saved += 1
      end
    end
    puts "#{events_found} events in Seattle kexp (#{events_saved} new)"
  end
end

