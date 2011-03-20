require 'load_events'

desc "This task is called by the Heroku cron add-on"
task :cron => :environment do

  #the only daily task we have is to load events
  start = Time.now
  puts "loading events..."
  events_saved = LoadEvents.load_events
  puts "saved #{events_saved} in #{Time.now - start} seconds"
end
