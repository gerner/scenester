require 'icalendar'

module Icalendar

  class RRule < Icalendar::Base

    DAYS_OF_WEEK = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]

    attr_accessor :by_list

    class Weekday
      attr_accessor :day, :position
      def ==(other)
        return other.day == day && (other.position == position || (other.position.blank? && position.blank?))
      end
    end

    # We have to monkey patch Icalendar's RRule since it's implementation of
    def occurrences_of_event_starting(event, datetime)
      # FREQ + INTERVAL means when the event happens starting with dtstart
      #   INTERVAL defaults to 1
      # optionally COUNT or UNTIL means when the event will stop recurring
      # BYDAY is a list of weekdays the event should occur on
      # BYSETPOS is an mask on the rule to indicate which elements are events
      # WKST specifies which day the week starts on and is important for 
      #   FREQ=WEEKLY and INTERVAL > 1 when BYDAY is set since INTERVAL=2
      #   means every other week, but what marks the week boundary (where 
      #   interval takes effect)?
      # also need to handle EXDATE
      
      # first make sure the date might still be valid
      if(@until && datetime > @until)
        return []
      end
      
      # plan:
      # dtstart is the first event
      # freq defines an interval of events i
      #   DAILY is a single day
      #   WEEKLY is the 7 days of the week (starting with WKST)
      #   MONTHLY is the days of the month
      #   we will determine instances from this sequence for every repeat 
      #   (meaning we need to recompute the sequence for every interval)
      # interval defines how the sequence repeats (e.g. every 1 month repeat the sequence)
      # wkst defines when the sequence starts for freq=WEEKLY (monday is default)
      # byXX sets or unsets instances in the interval
      #   BYDAY can have an integer which applies to MONTHLY repeat meaning the nth event
      #   (can be negative meaning count from end of month)
      #   BYMONTHDAY is an integer which means only that day of the month applies
      #   (can be negative meaning count from end of month)
      # bysetpos is applied to the resulting interval sequence to select only some of the events
      #   might be negative (counts from end)
      # exdate excludes specific events after rule parsing (this will have to be handled externally to the rrule)

      # we'll implement this as an iterator following the above algorithm

      # TODO: if you want to handle < DAILY freq it'll need to be handled separately from the below stuff
      #   the below stuff all assumes the unit of events is days
      # first get the very interval of candidate days (including DTSTART)

      seq = interval_sequence(event.dtstart, @frequency, @wkst)

      initial_start = event.dtstart
      (0...@count).map {|day_offset| 
              occurrence = event.clone
              occurrence.dtstart = initial_start + day_offset
              occurrence.clone
              }
    end

    # returns a list of events for the given interval of days
    # this will apply BYXX rules (including BYSETPOS)
    def materialize_day_interval(event, seq_size, start_date)
      # first element of seq is start_date
      
      duration_secs = event.dtend - event.dtstart
      events = []
      if @frequency == "DAILY" && !@by_list[:bymonthday] && !@by_list[:byday]
          e = event.clone
          e.dtstart = start_date
          events << e
      end

      if @by_list[:bymonthday]
        case @frequency
        when "DAILY"
          if @by_list[:bymonthday].include? start_date.mday
            e = event.clone
            e.dtstart = start_date
            events << e
          end
        when "WEEKLY"
          raise "can't apply BYMONTHDAY for WEEKLY"
        when "MONTHLY"
          @by_list[:bymonthday].each do |i|
            # indexing of bymonthday is wierd:
            #   1 => the first day
            #   -1 => the last day (equiv to -1 % # of days in month)
            #   0 doesn't exist?
            #   so positive numbers are 1 indexed
            #   negative numbers are 0 indexed
            i = i - 1 if i > 0
            i = i % seq_size if i < 0 
            e = event.clone
            e.dtstart = start_date.advance(:days => i)
            e.dtend = e.dtstart.advance(:seconds => duration_secs)
            events << e
          end 
        else
          raise "we don't support #{@frequency} frequency"
        end
      end

      if @by_list[:byday]
        if @by_list[:bymonthday]
          raise "we don't support BYDAY and BYMONTHDAY at the same time!"
        end

        case @frequency
        when "DAILY"
          if @by_list[:byday].include? Weekday.new(DAYS_OF_WEEK[start_date.wday], nil)
            e = event.clone
            e.dtstart = start_date
            e.dtend = e.dtstart.advance(:secs => duration_secs)
            events << e
          end
        when "WEEKLY"
          #for each day in seq, add an event if that day appears in byday
          wkst = @wkst ? DAYS_OF_WEEK.index(@wkst) : 1
          (wkst..wkst+seq_size).each do |i|
            next unless @by_list[:byday].include? Weekday.new(DAYS_OF_WEEK[i%7], nil)
            e = event.clone
            e.dtstart = start_date.advance(:days => i)
            e.dtend = e.dtstart.advance(:seconds => duration_secs)
            events << e
          end
        when "MONTHLY"
          #TODO: this is complicated...
          # we must support both day of week as well as integer indexing into days of week
          # e.g. -1MO => last monday, 2TU => second tuesday, ...
          
          # pass over the interval applying the non-numbered days
          (0..seq_size).each do |i|
            if @by_list[:byday].include? Weekday.new(DAYS_OF_WEEK[start_date.advance(:days => i).wday], nil)
              e = event.clone
              e.dtstart = start_date.advance(:days => i)
              e.dtend = e.dtstart.advance(:seconds => duration_secs)
              events << e
            end
          end

          # compute the first weekday for each day of the week
          #   wday[i].advance(:weeks => 1) is the second...
          wday = [[]] * 7 #we assume 7 days in a week!
          s = start_date
          (0..Time::days_in_month(start_date.month)).each do |i|
            s = s.advance(:days => i)
            wday[s.wday] << s
          end

          # pass over the numbered days applying simple calculations
          @by_list[:byday].each do |w|
            if w.position > 0 && wday[w.position]
              e = event.clone
              e.dtstart = wday[DAYS_OF_WEEK.index(w.day)][w.position-1]
              e.dtend = e.dtstart.advance(:seconds => duration_secs)
              events << e
            elsif w.position < 0 && wday[w.position]
              e = event.clone
              e.dtstart = wday[DAYS_OF_WEEK.index(w.day)][w.position]
              e.dtstart = e.dtstart.advance(:seconds => duration_secs)
              events << e
            end
          end

        else
          raise "we don't support #{@frequency} frequency"
        end
      end

      if @by_list[:bysetpos]
        raise "we don't support bysetpos yet!"
      end

      if @by_list[:bymonth] || @by_list[:byweekno] || @by_list[:byyearday] || @by_list[:byhour] || @by_list[:byminute] || @by_list[:bysecond]
        raise "we don't support bymonth, byweekno, byyearday, byhour, byminute, bysecond"
      end

      return events
    end

    # returns the interval of day which includes the specified date
    #   each element in sequence is nil or an event
    # this will apply FREQ and WKST
    def get_day_interval(event, datetime)
      seq = []
      case @frequency
      when "DAILY"
        seq_size = 1
        start_date = event.dtstart
      when "WEEKLY"
        wkst = @wkst ? DAYS_OF_WEEK.index(@wkst) : 1
        seq_size = 7
        start_date = event.dtstart.advance(:days => -((event.dtstart.wday - wkst) % 7))
      when "MONTHLY"
        seq_size = Time::days_in_month(event.dtstart.month, event.dtstart.year)
        start_date = event.dtstart.advance(:days => -(event.dtstart.day - 1))
      else
        raise "we don't support any freq other than DAILY, WEEKLY, MONTHLY. definitely not #{@freq}"
      end

      return [seq_size, start_date]
    end
  end
end

