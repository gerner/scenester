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

  test "test get_day_interval monthly" do
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
  
  test "test get_day_interval weekly" do
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

  test "test get_day_interval daily" do
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

  test "test materialize filtered daily" do
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

    # some assertions about the behavior of the icalendar parsing
    # this is mostly testing my Weekday equality override
    assert_equal(2, start_date.wday)
    assert(!(e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[2], nil)))
    assert((e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[3], nil)))
    assert((e.recurrence_rules.first.by_list[:byday].include? Icalendar::RRule::Weekday.new(Icalendar::RRule::DAYS_OF_WEEK[4], nil)))
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

end
