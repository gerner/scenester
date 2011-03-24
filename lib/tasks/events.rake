require 'net/http'
require 'uri'
require 'time'
require 'json'
require 'iconv'

require 'rubygems'
require 'rmeetup'
require 'xml'
require 'amatch'

namespace :events do

  desc "find duplicate events"
  task :duplicates => :environment do
    #get some events that we want to check
    events = Event.where("start > ? AND start < ?", Time.now.advance(:days => -1), Time.now.advance(:days => 1))
    candidates = Event.where("start > ? AND start < ?", Time.now.advance(:days => -1), Time.now.advance(:days => 1))
    events.each do |event|
      #find candidate duplicates
      candidates.each do |candidate|
        next if event.id == candidate.id
        #compute several similarity measures
        # title exact match?
        title_exact = event.title == candidate.title ? 1 : 0
        # some similarity measure between titles
        title_similarity  = event.title.levenshtein_similar(candidate.title)
        #venue exact match?
        venue_exact = event.venue_id == candidate.venue_id ? 1 : 0
        #venue similarity
        if event.venue_id == candidate.venue_id
          venue_similarity = 1
        elsif event.venue && candidate.venue
          venue_similarity = event.venue.name.levenshtein_similar(candidate.venue.name)
        else
          venue_similarity = 0
        end
        # url matches?
        url_matches = event.url == candidate.url ? 1 : 0
        # source matches?
        source_matches = event.source == candidate.source ? 0 : 1
        # difference squared in start times
        start_diff = 1 - (((event.start - candidate.start) ** 2.0) / 29859840000.0)
        #output likely duplicates
        score = (title_exact + title_similarity + url_matches + source_matches + start_diff + venue_exact + venue_similarity)/7.0
        #puts "#{score}"
        if (score > 0.3 && title_exact < 1)
          puts "#{score} #{event.id} and #{candidate.id} score:|#{score}: #{title_similarity} #{venue_similarity} #{url_matches} #{source_matches} #{start_diff}|\t#{event.title}|\t#{candidate.title}"
        end
        #if (score > 0.5)
#        if (rand > 0.999)
#          puts "#{event.title.gsub(","," ")},#{candidate.title.gsub(","," ")},#{title_exact},#{title_similarity},#{venue_exact},#{venue_similarity},#{url_matches},#{source_matches},#{start_diff}"
#        end
      end
    end
  end
  
  desc "print events"
  task :print => :environment do
    events = Event.order("start").all
    events.each do |e|
      puts "#{e.inspect}"
    end
    puts "#{events.size} events in database"
  end

  desc "load events"
  task :load, :source, :needs => :environment do |t, args|
    source = args[:source]

    LoadEvents.logger Logger.new(STDOUT)

    if !source
      puts "you must specify a source (or all for all sources)"
    elsif source == "all"
      puts "loading all events"
      LoadEvents.load_events
    elsif LoadEvents.method_names.index("load_"+source)
      puts "loading events from #{source}"
      LoadEvents.send(("load_"+source).to_sym)
    else
      puts "unknown source \"#{source}\""
      puts "#{LoadEvents.method_names}"
    end
  end

end

