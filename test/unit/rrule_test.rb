require 'test_helper'
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
    seq = e.recurrence_rules.first.get_day_interval(e, e.dtstart)
    assert_equal(Time::days_in_month(e.dtstart.month), seq.size)
  end

end
