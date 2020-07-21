defmodule Tox.DateTimeTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Tox.DateTime

  @utc_only Calendar.UTCOnlyTimeZoneDatabase

  describe "shift/3" do
    test "subtracts a year" do
      datetime = DateTime.from_naive!(~N[2000-02-24 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1999-02-24 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: -1) == expected
    end

    test "add a year in a leap year" do
      datetime = DateTime.from_naive!(~N[2020-02-29 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2021-02-28 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: 1) == expected
    end

    test "returns a datetime before a gap" do
      datetime = DateTime.from_naive!(~N[1992-03-31 02:10:30.123], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1991-03-31 01:10:30.123], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: -1) == expected
    end

    test "returns a datetime after a gap" do
      datetime = DateTime.from_naive!(~N[1991-03-29 02:10:30.123], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1992-03-29 03:10:30.123], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: 1) == expected
    end

    test "adds a year with a resulting ambiguous period (dst)" do
      datetime = DateTime.from_naive!(~N[2018-10-27 02:10:30.123], "Europe/Berlin")

      {:ambiguous, expected, _} =
        DateTime.from_naive(~N[2019-10-27 02:10:30.123], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: 1) == expected
    end

    test "adds a month at new year" do
      datetime = DateTime.from_naive!(~N[2000-01-01 00:00:00], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-01 00:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "adds a month at the end of the 31th January." do
      datetime = DateTime.from_naive!(~N[2000-01-31 23:59:59], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-29 23:59:59], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "adds a month at the beginning of the 31th January." do
      datetime = DateTime.from_naive!(~N[2000-01-31 00:00:00], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-29 00:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "adds a month" do
      datetime = DateTime.from_naive!(~N[2000-02-10 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-03-10 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "adds a month at the end of the year" do
      datetime = DateTime.from_naive!(~N[2000-12-31 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2001-01-31 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "adds a month in November" do
      datetime = DateTime.from_naive!(~N[2000-11-11 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-12-11 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 1) == expected
    end

    test "subtracts a month in February" do
      datetime = DateTime.from_naive!(~N[2000-02-11 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-01-11 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: -1) == expected
    end

    test "subtracts 12 months or a year" do
      datetime = DateTime.from_naive!(~N[2000-02-11 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1999-02-11 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: -1) == expected
      assert Tox.DateTime.shift(datetime, month: -12) == expected
    end

    test "subtracts 24 months or two years" do
      datetime = DateTime.from_naive!(~N[2000-02-11 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1998-02-11 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, year: -2) == expected
      assert Tox.DateTime.shift(datetime, month: -24) == expected
    end

    test "subtracts a month at the start of the year" do
      datetime = DateTime.from_naive!(~N[2000-01-01 00:00:00], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[1999-12-01 00:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: -1) == expected
    end

    test "adds a day" do
      datetime = DateTime.from_naive!(~N[2000-02-10 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-11 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, day: 1) == expected
    end

    test "adds a day at the end of a month" do
      datetime = DateTime.from_naive!(~N[2000-01-31 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-01 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, day: 1) == expected
    end

    test "subtracts a day at the begin of a month" do
      datetime = DateTime.from_naive!(~N[2000-03-01 12:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-02-29 12:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, day: -1) == expected
    end

    test "adds a hour at the end of a year" do
      datetime = DateTime.from_naive!(~N[2000-12-31 23:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2001-01-01 00:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, hour: 1) == expected
    end

    test "adds two month and one hour" do
      datetime = DateTime.from_naive!(~N[2000-01-31 23:10:30], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-04-01 00:10:30], "Europe/Berlin")

      assert Tox.DateTime.shift(datetime, month: 2, hour: 1) == expected
    end

    test "add/subtracts time up to the previous/next day" do
      earlier = DateTime.from_naive!(~N[2000-01-30 20:49:50], "Europe/Berlin")
      later = DateTime.from_naive!(~N[2000-01-31 12:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(later, hour: -15, minute: -10, second: -10) == earlier
      assert Tox.DateTime.shift(earlier, hour: 15, minute: 10, second: 10) == later
    end

    test "add/subtracts time up to the later/earlier day" do
      earlier = DateTime.from_naive!(~N[2000-01-10 20:49:50], "Europe/Berlin")
      later = DateTime.from_naive!(~N[2000-01-14 12:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(later, hour: -87, minute: -10, second: -10) == earlier
      assert Tox.DateTime.shift(earlier, hour: 87, minute: 10, second: 10) == later
    end

    test "add/subtracts 24 hours" do
      earlier = DateTime.from_naive!(~N[2000-01-10 01:00:00], "Europe/Berlin")
      later = DateTime.from_naive!(~N[2000-01-12 00:00:00], "Europe/Berlin")

      assert Tox.DateTime.shift(later, hour: -46, minute: -59, second: -60) == earlier
      assert Tox.DateTime.shift(earlier, hour: 46, minute: 59, second: 60) == later
    end

    test "resulting in a gap with coptic calendar" do
      datetime = %DateTime{
        calendar: Cldr.Calendar.Coptic,
        day: 3,
        hour: 2,
        microsecond: {860_034, 6},
        minute: 31,
        month: 9,
        second: 28,
        std_offset: 3600,
        time_zone: "CET",
        utc_offset: 3600,
        year: 1785,
        zone_abbr: "CEST"
      }

      assert Tox.DateTime.shift(datetime, microsecond: -142, day: -44, year: 159) ==
               %DateTime{
                 calendar: Cldr.Calendar.Coptic,
                 day: 19,
                 hour: 3,
                 microsecond: {859_892, 6},
                 minute: 31,
                 month: 7,
                 second: 28,
                 std_offset: 3600,
                 time_zone: "CET",
                 utc_offset: 3600,
                 year: 1944,
                 zone_abbr: "CEST"
               }
    end

    test "adds all durations" do
      datetime = DateTime.from_naive!(~N[2000-01-31 23:10:30.000001], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2001-03-02 00:11:31.001002], "Europe/Berlin")

      durations = [
        year: 1,
        month: 1,
        day: 1,
        hour: 1,
        minute: 1,
        second: 1,
        millisecond: 1,
        microsecond: 1
      ]

      assert Tox.DateTime.shift(datetime, durations) == expected
    end

    test "adds no durations" do
      {:ambiguous, datetime, _} =
        DateTime.from_naive(~N[2063-04-01 02:37:21], "Australia/Victoria")

      assert Tox.DateTime.shift(datetime, []) == datetime
    end

    test "adds in falling direction" do
      datetime = DateTime.from_naive!(~N[2000-11-30 12:00:00], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2000-12-31 12:00:00], "Europe/Berlin")

      assert datetime |> Tox.DateTime.shift(day: 1, month: 1) == expected
      assert datetime |> Tox.DateTime.shift(month: 1) |> Tox.DateTime.shift(day: 1) == expected

      assert datetime |> Tox.DateTime.shift(day: 1) |> Tox.DateTime.shift(month: 1) ==
               DateTime.from_naive!(~N[2001-01-01 12:00:00], "Europe/Berlin")
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2000-11-30 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.shift.*utc_only_time_zone_database/, fn ->
        Tox.DateTime.shift(datetime, [hour: 1], @utc_only)
      end
    end

    test "subtract hours starting in an ambiguous period (earlier)" do
      {:ambiguous, datetime, _} = DateTime.from_naive(~N[2068-10-28 01:06:51.201907], "Portugal")
      expected = DateTime.from_naive!(~N[2068-10-26 01:06:51.201907], "Portugal")

      assert Tox.DateTime.shift(datetime, hour: -48) == expected
    end

    test "subtract hours starting in an ambiguous period (later)" do
      {:ambiguous, _, datetime} = DateTime.from_naive(~N[2068-10-28 01:06:51.201907], "Portugal")
      expected = DateTime.from_naive!(~N[2068-10-26 02:06:51.201907], "Portugal")

      assert Tox.DateTime.shift(datetime, hour: -48) == expected
    end
  end

  describe "beginning_of_day/2" do
    test "returns beginning of day in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-29 00:00:00], "Etc/UTC")

      assert Tox.DateTime.beginning_of_day(datetime, @utc_only) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.beginning.of.day.*utc_only/, fn ->
        Tox.DateTime.beginning_of_day(datetime, @utc_only)
      end
    end

    test "raises an error for an invalid map" do
      message =
        "cannot set %{calendar: Calendar.ISO, day: 111, microsecond: {0, 0}, " <>
          "month: 11, time_zone: \"Europe/Berlin\", year: 2020} to beginning " <>
          "of day, reason: :invalid_date"

      assert_raise ArgumentError, message, fn ->
        Tox.DateTime.beginning_of_day(%{
          calendar: Calendar.ISO,
          time_zone: "Europe/Berlin",
          year: 2020,
          month: 11,
          day: 111,
          microsecond: {0, 0}
        })
      end
    end
  end

  describe "beginning_of_week/2" do
    test "returns beginning of day in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-23 00:00:00], "Etc/UTC")

      assert Tox.DateTime.beginning_of_week(datetime, @utc_only) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.beginning.of.day.*utc_only/, fn ->
        Tox.DateTime.beginning_of_week(datetime, @utc_only)
      end
    end
  end

  describe "beginning_of_month/2" do
    test "returns beginning of day in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-01 00:00:00], "Etc/UTC")

      assert Tox.DateTime.beginning_of_month(datetime, @utc_only) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.beginning.of.day.*utc_only/, fn ->
        Tox.DateTime.beginning_of_year(datetime, @utc_only)
      end
    end
  end

  describe "beginning_of_year/2" do
    test "returns beginning of day in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-01-01 00:00:00], "Etc/UTC")

      assert Tox.DateTime.beginning_of_year(datetime, @utc_only) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.beginning.of.day.*utc_only/, fn ->
        Tox.DateTime.beginning_of_year(datetime, @utc_only)
      end
    end
  end

  describe "end_of_day/2" do
    test "returns end of day in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-29 23:59:59.999999], "Etc/UTC")

      assert Tox.DateTime.end_of_day(datetime, @utc_only) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.end.of.day.*utc_only/, fn ->
        Tox.DateTime.end_of_day(datetime, @utc_only)
      end
    end
  end

  describe "end_of_week/2" do
    test "returns end of week in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-20 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-22 23:59:59.999999], "Etc/UTC")

      assert Tox.DateTime.end_of_week(datetime, @utc_only) ==
               expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.end.of.day.*utc_only/, fn ->
        Tox.DateTime.end_of_week(datetime, @utc_only)
      end
    end
  end

  describe "end_of_month/2" do
    test "returns end of month in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-19 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-03-31 23:59:59.999999], "Etc/UTC")

      assert Tox.DateTime.end_of_month(datetime, @utc_only) ==
               expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.end.of.day.*utc_only/, fn ->
        Tox.DateTime.end_of_month(datetime, @utc_only)
      end
    end
  end

  describe "end_of_year/2" do
    test "returns end of year in UTC" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Etc/UTC")
      expected = DateTime.from_naive!(~N[2020-12-31 23:59:59.999999], "Etc/UTC")

      assert Tox.DateTime.end_of_year(datetime, @utc_only) == expected
    end

    test "returns end of year resulting in gap" do
      datetime = DateTime.from_naive!(~N[1994-02-19 07:14:12.222457], "Pacific/Kiritimati")
      expected = DateTime.from_naive!(~N[1994-12-30 23:59:59.999999], "Pacific/Kiritimati")

      assert Tox.DateTime.end_of_year(datetime) == expected
    end

    test "raises an error" do
      datetime = DateTime.from_naive!(~N[2020-03-29 12:00:00], "Europe/Berlin")

      assert_raise ArgumentError, ~r/cannot.set.*to.end.of.day.*utc_only/, fn ->
        Tox.DateTime.end_of_year(datetime, @utc_only)
      end
    end
  end

  property "shift/3" do
    check all datetime <- Generator.datetime(),
              durations <- Generator.durations() do
      assert valid_datetime?(Tox.DateTime.shift(datetime, durations))
    end
  end

  property "beginning_of_day/1" do
    check all datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.beginning_of_day(datetime)
      assert result.year == datetime.year
      assert result.month == datetime.month
      assert result.day == datetime.day
      assert DateTime.compare(result, datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_month/1" do
    check all datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.beginning_of_month(datetime)
      assert result.year == datetime.year
      assert result.month == datetime.month
      assert result.day == 1
      assert DateTime.compare(result, datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_week/1" do
    check all %{calendar: calendar} = datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.beginning_of_week(datetime)

      year_range = (datetime.year - 1)..datetime.year

      months = calendar.months_in_year(datetime.year)

      month_range =
        months..1
        |> Stream.cycle()
        |> Enum.slice(months - datetime.month, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert calendar.day_of_week(result.year, result.month, result.day) == 1
      assert DateTime.compare(result, datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_year/1" do
    check all datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.beginning_of_year(datetime)
      assert result.year == datetime.year
      assert result.month == 1
      assert result.day == 1
      assert DateTime.compare(result, datetime) in [:lt, :eq]
    end
  end

  property "end_of_day/1" do
    check all datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.end_of_day(datetime)
      assert result.year == datetime.year
      assert result.month == datetime.month
      assert result.day == datetime.day
      assert DateTime.compare(result, datetime) in [:gt, :eq]
    end
  end

  property "end_of_month/1" do
    check all %{calendar: calendar} = datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.end_of_month(datetime)
      assert result.year == datetime.year
      assert result.month == datetime.month
      assert result.day == calendar.days_in_month(result.year, result.month)
      assert DateTime.compare(result, datetime) in [:gt, :eq]
    end
  end

  property "end_of_week/1" do
    check all %{calendar: calendar} = datetime <- Generator.datetime() do
      assert %DateTime{} = result = Tox.DateTime.end_of_week(datetime)

      year_range = datetime.year..(datetime.year + 1)

      months = calendar.months_in_year(datetime.year)

      month_range =
        1..months
        |> Stream.cycle()
        |> Enum.slice(datetime.month - 1, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert calendar.day_of_week(result.year, result.month, result.day) == 7
      assert DateTime.compare(result, datetime) in [:gt, :eq]
    end
  end

  property "end_of_year/1" do
    check all %{calendar: calendar} = datetime <- Generator.datetime() do
      months = calendar.months_in_year(datetime.year)

      assert %DateTime{} = result = Tox.DateTime.end_of_year(datetime)
      assert result.year == datetime.year
      assert result.month == months
      days = calendar.days_in_month(result.year, result.month)
      # In some time zones near the date line the last day in year can fall in a gap.
      assert result.day in (days - 1)..days
      assert DateTime.compare(result, datetime) in [:gt, :eq]
    end
  end

  defp valid_datetime?(%DateTime{
         calendar: calendar,
         year: year,
         month: month,
         day: day,
         hour: hour,
         minute: minute,
         second: second,
         microsecond: microsecond
       }) do
    calendar.valid_date?(year, month, day) &&
      calendar.valid_time?(hour, minute, second, microsecond)
  end

  defp valid_datetime?(_datetime), do: false
end
