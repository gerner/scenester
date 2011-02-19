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
      res = Net::HTTP.get(URI.parse("http://www.eventbrite.com/json/event_search?app_key=ZGI0YzliZjIzMTkx&city=Seattle&max=100&page=#{page_number}&date=this+month"))
      results = JSON.parse(res)
      break unless results["events"] && results["events"].size > 1
      page_number += 1
      results["events"][1..results["events"].size-1].each do |event|
        event = event["event"]
        events_found += 1
        unless Event.where(:title => event["title"]).count > 0
          e = Event.new
          e.image = event["logo"]
          e.title = event["title"]
          e.url = event["url"]
          e.venue = event["venue"]["name"]
          e.start = Time.parse(event["start_date"])
          e.end = Time.parse(event["end_date"])
          e.tags = event["category"] + ", " + event["tags"]
          e.source = "eventbrite"
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
    

    results = RMeetup::Client.fetch(:events,{:zip => "98116", :before => "2011-02-20T00:00:00"})

    group_ids = (results.collect { |event| event.group_id } ).join(",")
    
    group_results = RMeetup::Client.fetch(:groups, {:id => group_ids})
    groups = {}
    group_results.each do |group|
      groups[group.id.to_s] = group
    end

    results.each do |event|
      events_found += 1
      unless Event.where(:title => Iconv.conv('utf-8', 'iso-8859-1', event.group_name + ":" + event.name)).count > 0
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
      unless Event.where(:title => event["e_name"]).count > 0
        e = Event.new
        e.image = ""
        e.title = event["e_name"]
        e.url = event["e_web"]
        e.venue = event["e_venue"]
        e.start = Time.parse(event["dates"][0]["start_date"])
        e.end = Time.parse(event["dates"][0]["end_date"])
        e.source = "brownpapertickets"
        e.tags = event["category"]
        e.save
        events_saved += 1
      end
      
    end
    puts "#{events_found} events in Seattle from brownpapertickets (#{events_saved} new)"
  end
end

