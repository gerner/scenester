require 'icalendar'

module Icalendar

  class RRule < Icalendar::Base

    DAYS_OF_WEEK = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]

    class Weekday
      attr_accessor :day, :position
      def ==(other)
        return other.day == day && other.position == position
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
    def materialize_day_interval(event, seq, start_date)
      # first element of seq is start_date
      
      duration_secs = event.dtend - event.dtstart
      events = []
      if @by_list[:bymonthday]
        case @frequency
        when "DAILY"
          events = [] unless @by_list[:bymonthday].include? start_date.mday
          events = seq.first
        when "WEEKLY"
          raise "can't apply bymonthday for WEEKLY"
        when "MONTHLY"
          (0..seq.size).each do |i|
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
        case @frequency
        when "DAILY"
          events = [] unless @by_list[:byday].include? Weekday.new(DAYS_OF_WEEK[start_date.wday], nil)
        when "WEEKLY"
          #for each day in seq, add an event if that day appears in byday
          wkst = DAYS_OF_WEEK.index(@wkst)
          (wkst..wkst+seq.size).each do |i|
            next unless @by_list[:byday].include? Weekday.new(DAYS_OF_WEEK[i%7], nil)
            e = event.clone
            e.dtstart = start_date.advance(:days => i)
            e.dtend = e.dtstart.advance(:seconds => duration_secs)
            events << e
          end
        when "MONTHLY"
          if @by_list[:bymonthday]
            raise "we don't support BYDAY and BYMONTHDAY at the same time!"
          end

          #TODO: this is complicated...

        else
          raise "we don't support #{@frequency} frequency"
        end
      end

      if @by_list[:bysetpos]
        puts "foo"
      end

      if @by_list[:bymonth] || @by_list[:byweekno] || @by_list[:byyearday] || @by_list[:byhour] || @by_list[:byminute] || @by_list[:bysecond]
        raise "we don't support bymonth, byweekno, byyearday, byhour, byminute, bysecond"
      end
    end

    # returns the interval of day which includes the specified date
    #   each element in sequence is nil or an event
    # this will apply FREQ and WKST
    def get_day_interval(event, datetime)
      seq = []
      case @frequency
      when "DAILY"
        # TODO: not sure if we should add the day that DTSTART is on...
        start_date = event.dtstart
        seq = [event.clone]
      when "WEEKLY"
        wkst = DAYS_OF_WEEK.index(@wkst)
        # TODO: not sure if we should add the day that DTSTART is on...
        #   do for WEEKLY
        seq = [nil] * ((event.dtstart.wday - wkst) % 7)
        seq << [event.clone]
        seq += [nil] * (7 - ((event.dtstart.wday - wkst) % 7) - 1)
      when "MONTHLY"
        seq = [nil] * Time::days_in_month(event.dtstart.month, event.dtstart.year)
        # TODO: not sure if we should add the day that DTSTART is on...
        #   don't for MONTHLY
      else
        raise "we don't support any freq other than DAILY, WEEKLY, MONTHLY. definitely not #{@freq}"
      end

      return seq
    end
  end
end

