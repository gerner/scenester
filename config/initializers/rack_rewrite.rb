#Scenester::Application.config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
require 'rack-rewrite'
Rails.application.config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
  #r301 '/about', 'http://fourthirtysix.com/about'
end
