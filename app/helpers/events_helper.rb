module EventsHelper
  def venue_name_address(e)
    if e.venue
      " at #{e.venue.name}, #{e.venue.address}"
    else
      ""
    end
  end

  def add_to_google_calendar(e)
    "<a href=\"http://www.google.com/calendar/event?action=TEMPLATE&text=#{CGI::escape(e.title)}&dates=#{e.start.utc.strftime("%Y%m%dT%H%M%SZ")}/#{e.end.utc.strftime("%Y%m%dT%H%M%SZ")}&location=#{CGI::escape(venue_name_address(e))}\"><img class=\"gcalbtn\" src=\"http://www.google.com/calendar/images/ext/gc_button6.gif\"></a>".html_safe
  end
end
