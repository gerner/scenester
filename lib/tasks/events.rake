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

  desc "get eventbrite events coming soon"
  task :eventbrite => :environment do
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
        e.venue = event["venue"]["name"]
        e.start = Time.parse(event["start_date"])
        e.end = Time.parse(event["end_date"])
        e.tags = event["category"] + ", " + event["tags"]
        e.source = "eventbrite"
        unless Event.find_matching(e).count > 0
          e.save
          events_saved += 1
          puts "saved #{event["title"]}"
        end
      end
    end
    puts "#{events_found} events in Seattle from eventbright (#{events_saved} new)"
  end

  desc "get meetup events coming soon"
  task :meetup => :environment do
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
      e.venue = Iconv.conv('utf-8', 'iso-8859-1', event.venue_name)
      e.start = event.time
      e.end = event.time
      e.source = "meetup"
      group = groups[event.group_id]
      topics = group.topics.collect { |t| t["name"]}
      e.tags = Iconv.conv('utf-8', 'iso-8859-1', topics.join(","))
      unless Event.find_matching(e).count > 0
        e.save
        events_saved += 1
      end
    end
    puts "#{events_found} events in Seattle from meetup (#{events_saved} new)"
  end

  desc "get brown paper tickets events"
  task :brownpapertickets => :environment do
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
      e.venue = event["e_venue"]
      e.start = Time.parse(event["dates"][0]["start_date"])
      e.end = Time.parse(event["dates"][0]["end_date"])
      e.source = "brownpapertickets"
      e.tags = event["category"]
      unless Event.find_matching(e).count > 0
        e.save
        events_saved += 1
      end
      
    end
    puts "#{events_found} events in Seattle from brownpapertickets (#{events_saved} new)"
  end

  desc "get Seattle Rep Events"
  task :seattlerep => :environment do
    #scrape http://www.seattlerep.org/Plays/Calendar/
    Time.zone = "Pacific Time (US & Canada)"
    baseDate = Time.now
    venue = "Seattle Repertory Theatre"
    res = Net::HTTP.get(URI.parse("http://www.seattlerep.org/Plays/Calendar/"))
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse

    #first we need to get all the plays that are showing (to get links)
    plays = {}
    nodes = d.find("id('nav')/li/ul/li/ul/li/a").each do |n|
      plays[n.children.first.to_s] = "http://www.seattlerep.org"+n.attributes["href"]
    end

    #then we need to get all the showings
    events_found = 0
    events_saved = 0
    nodes = d.find("id('calendarMonth')/tr/td[@class!='otherMonth']").each do |n|
      #get the label which tells us the day
      day = n.find_first("label").first.to_s.to_i
      baseDate = Time.local(baseDate.year, baseDate.month, day)
      #get each div that is not class "iconDesc"
      n.find("div[@class!='iconDesc']").each do |show|
        events_found += 1
        #inside that is the title of the event followed by a <br /> element followed by the time (e.g. 2:00 PM 7:30 PM)
        t = Time.parse(show.children[2].to_s)
        t = Time.local(baseDate.year, baseDate.month, baseDate.day, t.hour, t.min)
        e = Event.new
        e.image = ""
        e.title = show.children[0].to_s
        e.url = plays[e.title]
        e.venue = venue
        e.start = t
        e.end = t.advance(:hours => 2)
        e.source = "seattlerep"
        e.tags = "Performing Arts"
        unless Event.find_matching(e).count > 0
          e.save
          events_saved += 1
        end
      end
    end
    puts "#{events_found} events in Seattle from seattlerep (#{events_saved} new)"
  end
  
  desc "get 5th Ave Theater Events"
  task :fifthave => :environment do
    #scrape http://www.seattlerep.org/Plays/Calendar/
    Time.zone = "Pacific Time (US & Canada)"
    baseDate = Time.now
    venue = "5th Avenue Theater"

    #first we need to get the plays that are showing
    res = Net::HTTP.get(URI.parse("http://www.5thavenue.org/show/"))
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
        e.url = plays[e.title]
        e.venue = venue
        e.start = t
        e.end = t
        e.source = "fifthave"
        e.tags = "Performing Arts"
        unless Event.find_matching(e).count > 0
          e.save
          events_saved += 1
        end
      end
    end
    puts "#{events_found} events in Seattle from seattlerep (#{events_saved} new)"
  end

  desc "get events from Seattle Weekly"
  task :seattleweekly => :environment do
    events_skipped = 0
    events_found = 0
    events_saved = 0
    Time.zone = "Pacific Time (US & Canada)"
    t = Time.now
    #res = Net::HTTP.get(URI.parse("http://www.seattleweekly.com/events/search/category:%5B293276%5D/date:#{t.year}-#{t.month}-#{t.day}/perPage:100/"))
    res = Net::HTTP.get(URI.parse("http://www.seattleweekly.com/events/search/date:#{t.year}-#{t.month}-#{t.day}/perPage:500/"))
    p = XML::HTMLParser.string(res, :options => XML::HTMLParser::Options::RECOVER | XML::HTMLParser::Options::NONET | XML::HTMLParser::Options::NOERROR | XML::HTMLParser::Options::NOWARNING)
    d = p.parse
    nodes = d.find("//div[@class='widget']//table/tr/td[@class='upper']")
    nodes.each do |n|
      e = Event.new
      e.image = ""
      e.title = n.find_first("h3/a").children[0].to_s.strip
      e.url = "http://www.seattleweekly.com"+n.find_first("h3/a").attributes["href"]
      e.venue = n.find_first("h4/a").children.first.to_s.strip
      e.source = "seattleweekly"
      eS = Time.new(t.year, t.month, t.day, 10, 0, 0)
      eE = eS.advance(:hours => 2)
      #TODO: do we really want to skip all daily events?
      if n.find_first("h4").children[2].to_s.index("Daily")
        events_skipped += 1
        next
      end
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
      e.start = eS
      e.end = eE
      tagNodes = n.parent.next.find("td[@class='grid_hdr second']/a")
      tagNodes = n.parent.next.next.find("td[@class='grid_hdr second']/a") unless tagNodes.size > 0
      tags = []
      tagNodes.each do |tag|
        tags << tag.first.to_s.strip
      end
      e.tags = tags.join(", ")
      unless Event.find_matching(e).count > 0
        e.save
        events_saved += 1
      end
    end
    puts "#{events_found} events in Seattle from seattleweekly_arts (#{events_saved} new, #{events_skipped} skipped)"
  end
end

