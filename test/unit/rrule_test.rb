require 'test_helper'
require 'icalendar'
require 'rrule'

class RRuleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "weekday accessors" do
    w = Icalendar::RRule::Weekday.new("SU", nil)
    assert_equal(w.position, nil)
    assert_equal(w.day, "SU")
  end

  test "weekday equality" do
    w = Icalendar::RRule::Weekday.new("SU", nil)
    assert_equal(w, Icalendar::RRule::Weekday.new("SU", nil))
    assert_not_equal(w, Icalendar::RRule::Weekday.new("SU", -1))
    assert_not_equal(w, Icalendar::RRule::Weekday.new("MO", nil))

    w2 = Icalendar::RRule::Weekday.new("MO", nil)
    assert([w, w2].include? Icalendar::RRule::Weekday.new("SU", nil))
    assert([w, w2].include? Icalendar::RRule::Weekday.new("MO", nil))
    assert(!([w, w2].include? Icalendar::RRule::Weekday.new("SU", -1)))

  end

  test "weekday parsing and equality" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=DAILY;BYDAY=WE,TH
END:VEVENT
END:VCALENDAR
    eos

    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    assert(e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new("WE", nil))

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)

    assert_equal(2, start_date.wday)
    assert(!(e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[2], nil)))
    assert((e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[3], nil)))
    assert((e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[4], nil)))
  end

  test "get_day_interval monthly" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=MONTHLY;BYDAY=TU;BYSETPOS=2
END:VEVENT
END:VCALENDAR
    eos

    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(Time::days_in_month(e.dtstart.month), seq_size)
    assert_equal(e.dtstart.month, start_date.month)
    assert_equal(e.dtstart.advance(:days => -(e.dtstart.day - 1)), start_date)
  end
  
  test "get_day_interval weekly" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=WEEKLY;BYDAY=TU
END:VEVENT
END:VCALENDAR
    eos

    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(7, seq_size)
    assert_equal(e.dtstart.advance(:days => -((e.dtstart.wday - 1) % 7)), start_date)
  end

  test "get_day_interval daily" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=DAILY;BYDAY=TU
END:VEVENT
END:VCALENDAR
    eos

    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(1, seq_size)
    assert_equal(e.dtstart, start_date)
  end

  test "materialize filtered daily" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=DAILY;BYDAY=WE,TH
END:VEVENT
END:VCALENDAR
    eos

    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)

    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date)
    assert_equal(0, events.size)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 1))
    assert_equal(1, events.size)
    assert_equal(start_date.advance(:days => 1), events.first.dtstart)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 2))
    assert_equal(1, events.size)
    assert_equal(start_date.advance(:days => 2), events.first.dtstart)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 3))
    assert_equal(0, events.size)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 4))
    assert_equal(0, events.size)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 5))
    assert_equal(0, events.size)
    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date.advance(:days => 6))
    assert_equal(0, events.size)
  end
  
  test "materialize filtered weekly" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=WEEKLY;BYDAY=TU,TH
END:VEVENT
END:VCALENDAR
    eos
    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(start_date, e.dtstart.advance(:days => -1))

    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date)
    assert_equal(2, events.size)
    assert_equal(e.dtstart, events[0].dtstart)

    assert_equal(2, events[0].dtstart.wday)
    assert_equal(e.dtstart.advance(:days => 2), events[1].dtstart)
    assert_equal(4, events[1].dtstart.wday)
  end

  test "materialize filtered monthly" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=MONTHLY;BYDAY=TU,TH,2FR,3FR,-1MO
END:VEVENT
END:VCALENDAR
    eos
    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(start_date, e.dtstart.advance(:days => -11))

    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date)
    assert_equal(8, events.size) #6 tu/th + 3rd friday + last monday

    base_date = start_date.advance(:days => -1)
    assert_equal(base_date.advance(:days => 12), events[0].dtstart)
    assert_equal(base_date.advance(:days => 14), events[1].dtstart)
    assert_equal(base_date.advance(:days => 15), events[2].dtstart)
    assert_equal(base_date.advance(:days => 19), events[3].dtstart)
    assert_equal(base_date.advance(:days => 21), events[4].dtstart)
    assert_equal(base_date.advance(:days => 25), events[5].dtstart)
    assert_equal(base_date.advance(:days => 26), events[6].dtstart)
    assert_equal(base_date.advance(:days => 28), events[7].dtstart)
  end
  
  test "materialize bysetpos" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=MONTHLY;BYDAY=TU,TH,2FR,3FR,-1MO;BYSETPOS=-2,-30,2,-1,100
END:VEVENT
END:VCALENDAR
    eos
    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(start_date, e.dtstart.advance(:days => -11))

    events = e.recurrence_rules.first.materialize_day_interval(e, seq_size, start_date)
    assert_equal(3, events.size) #6 tu/th + 3rd friday + last monday

    base_date = start_date.advance(:days => -1)
    assert_equal(base_date.advance(:days => 14), events[0].dtstart)
    assert_equal(base_date.advance(:days => 26), events[1].dtstart)
    assert_equal(base_date.advance(:days => 28), events[2].dtstart)
  end
  
  test "event iterator with count" do
    cal_data = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=America/Los_Angeles:20110412T190000
DTEND;TZID=America/Los_Angeles:20110412T220000
RRULE:FREQ=MONTHLY;BYDAY=TU,TH;BYSETPOS=2,4,6,8,10;COUNT=10
END:VEVENT
END:VCALENDAR
    eos
    cals = Icalendar.parse(cal_data)
    e = cals.first.events.first

    base_date = e.dtstart.advance(:days => -11).advance(:months => 1).advance(:days => -1)

    events = e.occurrences_starting(base_date.advance(:days => 12))

    assert_equal(6, events.size)
    assert_equal(base_date.advance(:days => 12), events[0].dtstart)
    assert_equal(base_date.advance(:days => 19), events[1].dtstart)
    assert_equal(base_date.advance(:days => 26), events[2].dtstart)
    assert_equal(base_date.advance(:days => 1).advance(:months => 1, :days => 6), events[3].dtstart)
    assert_equal(base_date.advance(:days => 1).advance(:months => 1, :days => 13), events[4].dtstart)
    assert_equal(base_date.advance(:days => 1).advance(:months => 1, :days => 20), events[5].dtstart)
  end

  #asserts that 
  def assert_event(e, y, m, d, events)
    e2 = e.dup
    e2.dtstart = DateTime.new(y, m, d, e.dtstart.hour, e.dtstart.min, e.dtstart.sec, e.dtstart.offset)
    assert(events.include?(e2), "events didn't include #{y}-#{m}-#{d}")
  end

  def assert_events(e, dates)
    events.each do |d|
    end
  end

  test "rfc 5545 examples" do
    cal_header = <<-eos
BEGIN:VCALENDAR
BEGIN:VEVENT
    eos

    cal_footer = <<-eos
END:VEVENT
END:VCALENDAR
    eos


    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=DAILY;COUNT=10
    eos
    # (1997 9:00 AM EDT) September 2-11
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(DateTime.new)
    assert_equal(10, events.size)
    assert_event(e, 1997, 9, 2, events)
    assert_event(e, 1997, 9, 3, events)
    assert_event(e, 1997, 9, 4, events)
    assert_event(e, 1997, 9, 5, events)
    assert_event(e, 1997, 9, 6, events)
    assert_event(e, 1997, 9, 7, events)
    assert_event(e, 1997, 9, 8, events)
    assert_event(e, 1997, 9, 9, events)
    assert_event(e, 1997, 9, 10, events)
    assert_event(e, 1997, 9, 11, events)



    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=DAILY;UNTIL=19971224T000000Z
    eos
    # (1997 9:00 AM EDT) September 2-30;October 1-31;November 1-30;December 1-23
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(DateTime.new)
    assert_equal(29+31+30+23, events.size)
    (2..30).each { |i| assert_event(e, 1997, 9, i, events) }
    (1..31).each { |i| assert_event(e, 1997, 10, i, events) }
    (1..30).each { |i| assert_event(e, 1997, 11, i, events) }
    (1..23).each { |i| assert_event(e, 1997, 12, i, events) }


    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5
    eos
    #(1997 9:00 AM EDT) September 2,12,22;
    #                   October 2,12
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(DateTime.new)
    assert_equal(5, events.size)
    assert_event(e, 1997, 9, 2, events)
    assert_event(e, 1997, 9, 12, events)
    assert_event(e, 1997, 9, 22, events)
    assert_event(e, 1997, 10, 2, events)
    assert_event(e, 1997, 10, 12, events)
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=WEEKLY;COUNT=10
    eos
    # (1997 9:00 AM EDT) September 2,9,16,23,30;October 7,14,21,28;November 4
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(e.dtstart)
    assert_equal(10, events.size)
    [2,9,16,23,30].each { |d| assert_event(e, 1997, 9, d, events) }
    [7,14,21,28].each { |d| assert_event(e, 1997, 10, d, events) }
    [4].each { |d| assert_event(e, 1997, 11, d, events) }

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z
    eos
    # (1997 9:00 AM EDT) September 2,9,16,23,30;
    #                    October 7,14,21,28;
    #                    November 4,11,18,25;
    #                    December 2,9,16,23
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(e.dtstart)
    assert_equal(17, events.size)
    [2,9,16,23,30].each { |d| assert_event(e, 1997, 9, d, events) }
    [7,14,21,28].each { |d| assert_event(e, 1997, 10, d, events) }
    [4,11,18,25].each { |d| assert_event(e, 1997, 11, d, events) }
    [2,9,16,23].each { |d| assert_event(e, 1997, 12, d, events) }

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH
    eos
    # (1997 9:00 AM EDT) September 2,4,9,11,16,18,23,25,30;October 2
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(e.dtstart)
    assert_equal(10, events.size)
    [2,4,9,11,16,18,23,25,30].each { |d| assert_event(e, 1997, 9, d, events) }
    [2].each { |d| assert_event(e, 1997, 10, d, events) }

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970901T090000
RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR
    eos
    # (1997 9:00 AM EDT) September 1,3,5,15,17,19,29;
    #                    October 1,3,13,15,17,27,29,31;
    #                    November 10,12,14,24,26,28;
    #                    December 8,10,12,22
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(e.dtstart)
    assert_equal(25, events.size)
    [1,3,5,15,17,19,29].each { |d| assert_event(e, 1997, 9, d, events) }
    [1,3,13,15,17,27,29,31].each { |d| assert_event(e, 1997, 10, d, events) }
    [10,12,14,24,26,28].each { |d| assert_event(e, 1997, 11, d, events) }
    [8,10,12,22].each { |d| assert_event(e, 1997, 12, d, events) }

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH
    eos
    # (1997 9:00 AM EDT) September 2,4,16,18,30;
    #                    October 2,14,16
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(e.dtstart)
    assert_equal(8, events.size)
    [2,4,16,18,30].each { |d| assert_event(e, 1997, 9, d, events) }
    [2,14,16].each { |d| assert_event(e, 1997, 10, d, events) }

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970905T090000
RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR
    eos
    # (1997 9:00 AM EDT) September 5;October 3
    # (1997 9:00 AM EST) November 7;December 5
    # (1998 9:00 AM EST) January 2;February 6;March 6;April 3
    # (1998 9:00 AM EDT) May 1;June 5
    e = Icalendar.parse(cal_header+cal_data+cal_footer).first.events.first
    events = e.occurrences_starting(DateTime.new)
    assert_equal(10, events.size)
    assert_event(e, 1997, 9, 5, events)
    assert_event(e, 1997, 10, 3, events)
    assert_event(e, 1997, 11, 7, events)
    assert_event(e, 1997, 12, 5, events)
    assert_event(e, 1998, 1, 2, events)
    assert_event(e, 1998, 2, 6, events)
    assert_event(e, 1998, 3, 6, events)
    assert_event(e, 1998, 4, 3, events)
    assert_event(e, 1998, 5, 1, events)
    assert_event(e, 1998, 6, 5, events)

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970905T090000
RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR
    eos
    # (1997 9:00 AM EDT) September 5; October 3
    # (1997 9:00 AM EST) November 7; December 5
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970907T090000
RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU
    eos
    # (1997 9:00 AM EDT) September 7,28
    # (1997 9:00 AM EST) November 2,30
    # (1998 9:00 AM EST) January 4,25;March 1,29
    # (1998 9:00 AM EDT) May 3,31
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970922T090000
RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO
    eos
    # (1997 9:00 AM EDT) September 22;October 20
    # (1997 9:00 AM EST) November 17;December 22
    # (1998 9:00 AM EST) January 19;February 16
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15
    eos
    #  (1997 9:00 AM EDT) September 2,15;October 2,15
    #  (1997 9:00 AM EST) November 2,15;December 2,15
    #  (1998 9:00 AM EST) January 2,15
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970930T090000
RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1
    eos
    # (1997 9:00 AM EDT) September 30;October 1
    # (1997 9:00 AM EST) October 31;November 1,30;December 1,31
    # (1998 9:00 AM EST) January 1,31;February 1

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970910T090000
RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15
    eos
    # (1997 9:00 AM EDT) September 10,11,12,13,14,15
    # (1999 9:00 AM EST) March 10,11,12,13

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970904T090000
RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3
    eos
    # (1997 9:00 AM EDT) September 4;October 7
    # (1997 9:00 AM EST) November 6

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970805T090000
RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO
    eos
    # (1997 EDT) August 5,10,19,24

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970805T090000
RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU
    eos
    # (1997 EDT) August 5,17,19,31
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:20070115T090000
RRULE:FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5
    eos
    # (2007 EST) January 15,30
    # (2007 EST) February 15
    # (2007 EDT) March 15,30
  end
end
