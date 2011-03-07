module VenuesHelper
  def google_map_embed venue
    html = "<iframe width=\"640\" height=\"480\" frameborder=\"0\" scrolling=\"no\" marginheight=\"0\" marginwidth=\"0\" src=\"http://maps.google.com/maps?f=q&amp;source=s_q&amp;hl=en&amp;geocode=&amp;q=#{CGI::escape venue.name},+#{CGI::escape venue.address}+#{CGI::escape venue.city},+#{CGI::escape venue.state}+#{CGI::escape venue.zipcode}&amp;aq=&amp;sll=#{venue.lat},#{venue.long}&amp;output=embed\"></iframe>"
  end
end
