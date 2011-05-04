require 'rubygems'
require 'foursquare'

#nick
authorization_code="EWPW4SAQO3THR24WGOJ4TSY5AK5VFSIVSTBG2HQAFYRFZLQ0"

#nick2
#authorization_code="ZLPPRTLKVH4DRM2PKC1SGYJGJJCZJ5SWNR0W30CVRNWXHF5E"

namespace :foursquare do

  desc "checkins"
  task :checkins => :environment do
    user = Foursquare::User.new(authorization_code)
    puts "getting checkins..."
    checkins = user.checkins["response"]["checkins"]["items"]
    puts "looking for matches..."
    checkins.each do |c|
      venue = c["venue"]["name"]
      t = Time.at(c["createdAt"])
      e = Event.find_attending(venue, t).first
      if e
        puts "You were attending \"#{e.title}\" at \"#{venue}\" at #{t.to_s}"
      else
        puts "  I don't know what you were doing at \"#{venue}\" at #{t.to_s}"
      end
    end
  end
end
