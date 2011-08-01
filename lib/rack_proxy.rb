require "net/http"

# Example Usage:
#
# use Rack::Proxy do |req|
#   if req.path =~ %r{^/remote/service.php$}
#     URI.parse("http://remote-service-provider.com/service-end-point.php?#{req.query}")
#   end
# end
#
# run proc{|env| [200, {"Content-Type" => "text/plain"}, ["Ha ha ha"]] }
#
class Rack::Proxy
  def initialize(app, &block)
    self.class.send(:define_method, :uri_for, &block)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    method = req.request_method.downcase
    method[0..0] = method[0..0].upcase

    return @app.call(env) unless uri = uri_for(req)

    sub_request = Net::HTTP.const_get(method).new("#{uri.path}#{"?" if uri.query}#{uri.query}")

    if sub_request.request_body_permitted? and req.body
      sub_request.body_stream = req.body
      sub_request.content_length = req.content_length
      sub_request.content_type = req.content_type
    end

    sub_request["X-Forwarded-For"] = (req.env["X-Forwarded-For"].to_s.split(/, +/) + [req.env['REMOTE_ADDR']]).join(", ")
    sub_request["X-Requested-With"] = req.env['HTTP_X_REQUESTED_WITH'] if req.env['HTTP_X_REQUESTED_WITH']
    sub_request["Accept-Encoding"] = req.accept_encoding
    sub_request["Referer"] = req.referer
    sub_request["Host"] = "fourthirtysix.com"
    sub_request["Cookie"] = req.env["HTTP_COOKIE"] if req.env["HTTP_COOKIE"]
    sub_request.basic_auth *uri.userinfo.split(':') if (uri.userinfo && uri.userinfo.index(':'))

    print "sending:\n#{sub_request.inspect} to #{uri.to_s}\n"
    print "cookie:\n#{sub_request["Cookie"]}\n"

    sub_response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sub_request)
    end
    
    print "received:\n#{sub_response.inspect}\n"

    headers = {}
    cookies = []
    sub_response.each_header do |k,v|
      print "processing header #{k}: #{v}\n"
      headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i
      if k.to_s =~ /cookie/i
        sub_response.get_fields(k).each do |v|
          key = nil
          cookie = {}
          v.split(";").each do |p|
            parts = p.split("=")
            cookie[:value] = parts[1].strip() unless key
            key = parts[0].strip() unless key
            case parts[0].strip()
            when "domain"
              cookie[:domain] = parts[1].strip()
            when "path"
              cookie[:path] = parts[1].strip()
            when "expires"
              cookie[:expires] = Time.parse(parts[1])
            when "secure"
              cookie[:secure] = true
            when "HttpOnly"
              cookie[:httponly] = true
            end
          end
          print "setting #{key} #{cookie}\n"
          Rack::Utils.set_cookie_header!(headers, key, cookie)
          print "set-cookie is now:\n#{headers["Set-Cookie"]}\n"
        end
      end
    end
    Rack::Utils.set_cookie_header!(headers, "foo", "bar")
    Rack::Utils.set_cookie_header!(headers, "baz", "blerf")

    [sub_response.code.to_i, headers,[sub_response.read_body]]
  end
end
