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
    sub_request["Cookie"] = req.env["rack.request.cookie_string"] if req.env["rack.request.cookie_string"]
    sub_request.basic_auth *uri.userinfo.split(':') if (uri.userinfo && uri.userinfo.index(':'))

    sub_response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sub_request)
    end

    headers = {}
    sub_response.each_header do |k,v|
      headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i 
    end

    response = Rack::Response.new([sub_response.read_body], sub_response.code.to_i, headers)

    print sub_response.get_fields('Set-Cookie')

    sub_response.get_fields('Set-Cookie') do |k,v| 
      response.set_cookie(k,v)
    end

    print response.inspect

    response.finish

  end
end