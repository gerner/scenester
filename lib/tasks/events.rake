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
    events = Event.where("start > ? AND start < ?", Time.now.advance(:days => -1), Time.now.advance(:days => 1)).includes(:venue)
    candidates = Event.where("start > ? AND start < ?", Time.now.advance(:days => -2), Time.now.advance(:days => 2)).includes(:venue)
    duplicates_found = 0
    events_with_duplicates = 0
    events.each do |event|
      duplicates = event.duplicates(:candidates => candidates)
      unless duplicates.empty?
        puts "#{event.id} #{event.title_with_venue} #{event.source} #{event.start.strftime("%e %l:%M%P")}"
        duplicates.each do |duplicate|
          puts "\t#{event.similarity(duplicate)} #{duplicate.id} #{duplicate.title_with_venue} #{duplicate.source} #{duplicate.start.strftime("%e %l:%M%P")}"
        duplicates_found += 1
        end
        events_with_duplicates += 1
      end
    end
    puts "#{events_with_duplicates} events with duplicates with #{duplicates_found} duplicates from #{events.size} events total"
  end

  task :pair_wise, :ratio, :needs => :environment do |t, args|
    ratio = args[:ratio].to_f || 0.0
    
    unless ratio > 0.0 && ratio <= 1.0
      puts "ratio must be in <0,1]"
      next
    end

    events = Event.where("start > ? AND start < ?", Time.now.advance(:days => -1), Time.now.advance(:days => 1)).includes(:venue)
    candidates = Event.where("start > ? AND start < ?", Time.now.advance(:days => -2), Time.now.advance(:days => 2)).includes(:venue)

    events.each do |event|
      candidates.each do |candidate|
        next if event.id == candidate.id
        next rand < ratio 
        features = event.similarity_vector(candidate)

        out_line = "#{event.id},#{candidate.id},#{event.title_with_venue.gsub(/,/,"")},#{candidate.title_with_venue.gsub(/,/,"")}"
        features.each do |k,v|
          out_line += ",#{v.to_s}"
        end
        puts out_line
      end
    end

  end
  
  desc "print events"
  task :print, :field, :needs => :environment do |t, args|
    field = args[:field]

    events = Event.order("start")
    if !field
      events.each do |e|
        puts "#{e.inspect}"
      end
      puts "#{events.size} events in database"
    elsif events.first.respond_to?(field)
      events.each do |e|
        puts "#{e.send(field.to_s)}"
      end
    else
      puts "#{field} not a field on event"
    end
  end

  desc "load events"
  task :load, :source, :needs => :environment do |t, args|
    source = args[:source]

    LoadEvents.logger Logger.new(STDOUT)

    if !source
      puts "you must specify a source (or all for all sources)"
      LoadEvents.sources.each do |v|
        puts "\t#{v}"
      end
    elsif source == "all"
      puts "loading all events"
      LoadEvents.load_events
    elsif LoadEvents.sources.index(source)
      puts "loading events from #{source}"
      events_loaded = LoadEvents.send(("load_"+source).to_sym)
      puts "loaded #{events_loaded} new events"
    else
      puts "unknown source \"#{source}\""
      LoadEvents.sources.each do |s|
        puts "\t#{s}"
      end
    end
  end

end

