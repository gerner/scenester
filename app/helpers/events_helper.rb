module EventsHelper
  def venue_name_address(e)
    if e.venue
      " at #{e.venue.name}, #{e.venue.address}"
    else
      ""
    end
  end
end
