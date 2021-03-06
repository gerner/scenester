class BlogController < ApplicationController
  def show
    result = fetch(
            "http://205.251.128.170/#{request.fullpath}")

    #render error if result. ...
    case response.code
      when "200" then 
        logger.info("success!")
        render :text => result.body
      else
        logger.error "#{response.code}, #{response}"
        render :status => response.code.to_i
    end
  end

  def fetch(uri_str, limit = 10)
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      logger.info(uri_str)

      response = Net::HTTP.get(URI.parse(uri_str), {"host" => "fourthirtysix.com"} )
      case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response
      end
  end
end
