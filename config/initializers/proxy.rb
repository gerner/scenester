require 'rack_proxy'

Rails.application.config.middleware.insert_before(Rack::Lock, Rack::Proxy) do |req|
  if req.path =~ %r{^/blog}
    URI.parse("http://205.251.128.170#{req.fullpath}")
  end
end
