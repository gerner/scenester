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

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)

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
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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
    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)

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

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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

    seq_size, start_date = e.recurrence_rules.first.get_day_interval(e.dtstart)
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

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=DAILY;UNTIL=19971224T000000Z
    eos
    # (1997 9:00 AM EDT) September 2-30;October 1-25
    # (1997 9:00 AM EST) October 26-31;November 1-30;December 1-23

    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5
    eos
    #(1997 9:00 AM EDT) September 2,12,22;
    #                   October 2,12
    
    cal_data = <<-eos
DTSTART;TZID=America/New_York:19970902T090000
RRULE:FREQ=WEEKLY;COUNT=10
    eos
    # (1997 9:00 AM EDT) September 2,9,16,23,30;October 7,14,21
    #  (1997 9:00 AM EST) October 28;November 4

  end
end
