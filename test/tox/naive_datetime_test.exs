defmodule Tox.NaiveDateTimeTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Tox.NaiveDateTime

  describe "shift/2" do
    test "adds a year" do
      assert Tox.NaiveDateTime.shift(~N[1999-01-15 10:11:12], year: 1) == ~N[2000-01-15 10:11:12]
    end

    test "subtracts a year" do
      assert Tox.NaiveDateTime.shift(~N[1999-01-15 10:11:12], year: -1) == ~N[1998-01-15 10:11:12]
    end

    test "adds a year and updates day" do
      assert Tox.NaiveDateTime.shift(~N[2000-02-29 10:11:12], year: 1) == ~N[2001-02-28 10:11:12]
    end

    test "subtracts a year and updates day" do
      assert Tox.NaiveDateTime.shift(~N[2000-02-29 10:11:12], year: -1) == ~N[1999-02-28 10:11:12]
    end

    test "adds a month" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-01 10:11:12], month: 1) == ~N[2000-02-01 10:11:12]
    end

    test "subtracts a month" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-01 10:11:12], month: -1) ==
               ~N[1999-12-01 10:11:12]
    end

    test "adds a month and updates day" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: 1) == ~N[2000-02-29 10:11:12]
    end

    test "subtracts a month and updates day" do
      assert Tox.NaiveDateTime.shift(~N[2000-03-31 10:11:12], month: -1) ==
               ~N[2000-02-29 10:11:12]
    end

    test "adds multiple months" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: 2) == ~N[2000-03-31 10:11:12]

      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: 11) ==
               ~N[2000-12-31 10:11:12]

      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: 12) ==
               ~N[2001-01-31 10:11:12]

      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: 13) ==
               ~N[2001-02-28 10:11:12]
    end

    test "subtracts multiple months" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: -2) ==
               ~N[1999-11-30 10:11:12]

      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: -11) ==
               ~N[1999-02-28 10:11:12]

      assert Tox.NaiveDateTime.shift(~N[2000-01-31 10:11:12], month: -12) ==
               ~N[1999-01-31 10:11:12]
    end

    test "adds a day" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-01 10:11:12], day: 1) == ~N[2000-01-02 10:11:12]
    end

    test "subtracts a day" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-10 10:11:12], day: -1) == ~N[2000-01-09 10:11:12]
    end

    test "adds multiple days and updates month and year" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-01 10:11:12], day: 450) == ~N[2001-03-26 10:11:12]
    end

    test "subtracts multiple days and updates month and year" do
      assert Tox.NaiveDateTime.shift(~N[2001-03-26 10:11:12], day: -450) ==
               ~N[2000-01-01 10:11:12]
    end

    test "adds years, months, and days" do
      assert Tox.NaiveDateTime.shift(~N[2000-01-01 10:11:12], year: 2, month: 3, day: 4) ==
               ~N[2002-04-05 10:11:12]
    end

    test "adds a week" do
      assert Tox.NaiveDateTime.shift(~N[2020-01-30 10:11:12], week: 1) == ~N[2020-02-06 10:11:12]
    end

    test "subtracts a week" do
      assert Tox.NaiveDateTime.shift(~N[2020-02-06 10:11:12], week: -1) == ~N[2020-01-30 10:11:12]
    end

    test "adds from the largest to the smallest unit" do
      date = ~N[2001-02-28 10:11:12]

      assert Tox.NaiveDateTime.shift(date, month: 1, day: 1) == ~N[2001-03-29 10:11:12]

      assert Tox.NaiveDateTime.shift(date, month: 1, day: 1) ==
               date |> Tox.NaiveDateTime.shift(month: 1) |> Tox.NaiveDateTime.shift(day: 1)

      assert date |> Tox.NaiveDateTime.shift(month: 1) |> Tox.NaiveDateTime.shift(day: 1) !=
               date |> Tox.NaiveDateTime.shift(day: 1) |> Tox.NaiveDateTime.shift(month: 1)
    end

    test "adds time" do
      assert Tox.NaiveDateTime.shift(
               ~N[2000-01-31 23:00:00.000001],
               hour: 5,
               minute: 15,
               second: 10,
               millisecond: 50,
               microsecond: 500
             ) == ~N[2000-02-01 04:15:10.050501]
    end

    test "subtracts time" do
      assert Tox.NaiveDateTime.shift(
               ~N[2000-02-01 04:15:10.050501],
               hour: -5,
               minute: -15,
               second: -10,
               millisecond: -50,
               microsecond: -500
             ) == ~N[2000-01-31 23:00:00.000001]
    end

    test "adds large amount of time" do
      assert Tox.NaiveDateTime.shift(
               ~N[2000-01-31 23:00:00.000001],
               hour: 24 * 3 + 5,
               minute: 75,
               second: 200,
               millisecond: 50,
               microsecond: 1_000_000
             ) == ~N[2000-02-04 05:18:21.050001]
    end

    test "subtracts large amount of time" do
      assert Tox.NaiveDateTime.shift(
               ~N[2000-02-04 05:18:21.050001],
               hour: -24 * 3 - 5,
               minute: -75,
               second: -200,
               millisecond: -50,
               microsecond: -1_000_000
             ) == ~N[2000-01-31 23:00:00.000001]
    end
  end

  describe "beginning_of_day/1" do
    test "raises an error for an invalid map" do
      message =
        "cannot set %{calendar: Calendar.ISO, day: 111, microsecond: {0, 0}, month: 11, " <>
          "year: 2020} to beginning of day, reason: :invalid_date"

      assert_raise ArgumentError, message, fn ->
        Tox.NaiveDateTime.beginning_of_day(%{
          calendar: Calendar.ISO,
          year: 2020,
          month: 11,
          day: 111,
          microsecond: {0, 0}
        })
      end
    end
  end

  describe "end_of_day/1" do
    test "raises an error for an invalid map" do
      message =
        "cannot set %{calendar: Calendar.ISO, day: 111, microsecond: {0, 0}, month: 11, " <>
          "year: 2020} to end of day, reason: :invalid_date"

      assert_raise ArgumentError, message, fn ->
        Tox.NaiveDateTime.end_of_day(%{
          calendar: Calendar.ISO,
          year: 2020,
          month: 11,
          day: 111,
          microsecond: {0, 0}
        })
      end
    end
  end

  property "shift/2" do
    check all naive_datetime <- Generator.naive_datetime(),
              durations <- Generator.durations() do
      assert valid_naive_datetime?(Tox.NaiveDateTime.shift(naive_datetime, durations))
    end
  end

  property "beginning_of_day/1" do
    check all naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.beginning_of_day(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == naive_datetime.month
      assert result.day == naive_datetime.day
      assert result.hour == 0
      assert result.minute == 0
      assert result.second == 0
      assert {0, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_month/1" do
    check all naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.beginning_of_month(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == naive_datetime.month
      assert result.day == 1
      assert result.hour == 0
      assert result.minute == 0
      assert result.second == 0
      assert {0, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_week/1" do
    check all %{calendar: calendar} = naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.beginning_of_week(naive_datetime)

      year_range = (naive_datetime.year - 1)..naive_datetime.year

      months = calendar.months_in_year(naive_datetime.year)

      month_range =
        months..1
        |> Stream.cycle()
        |> Enum.slice(months - naive_datetime.month, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert result.hour == 0
      assert result.minute == 0
      assert result.second == 0
      assert {0, _precision} = result.microsecond
      assert {day_of_week, day_of_week, _last_day_of_week} = Tox.Calendar.day_of_week(result)
      assert NaiveDateTime.compare(result, naive_datetime) in [:lt, :eq]
    end
  end

  property "beginning_of_year/1" do
    check all naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.beginning_of_year(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == 1
      assert result.day == 1
      assert result.hour == 0
      assert result.minute == 0
      assert result.second == 0
      assert {0, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:lt, :eq]
    end
  end

  property "end_of_day/1" do
    check all naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.end_of_day(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == naive_datetime.month
      assert result.day == naive_datetime.day
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
      assert {999_999, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:gt, :eq]
    end
  end

  property "end_of_month/1" do
    check all %{calendar: calendar} = naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.end_of_month(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == naive_datetime.month
      assert result.day == calendar.days_in_month(result.year, result.month)
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
      assert {999_999, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:gt, :eq]
    end
  end

  property "end_of_week/1" do
    check all %{calendar: calendar} = naive_datetime <- Generator.naive_datetime() do
      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.end_of_week(naive_datetime)

      year_range = naive_datetime.year..(naive_datetime.year + 1)

      months = calendar.months_in_year(naive_datetime.year)

      month_range =
        1..months
        |> Stream.cycle()
        |> Enum.slice(naive_datetime.month - 1, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert Tox.day_of_week(calendar, result.year, result.month, result.day) == 7
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
      assert {999_999, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:gt, :eq]
    end
  end

  property "end_of_year/1" do
    check all %{calendar: calendar} = naive_datetime <- Generator.naive_datetime() do
      months = calendar.months_in_year(naive_datetime.year)

      assert %NaiveDateTime{} = result = Tox.NaiveDateTime.end_of_year(naive_datetime)
      assert result.year == naive_datetime.year
      assert result.month == months
      assert result.day == calendar.days_in_month(naive_datetime.year, months)
      assert result.hour == 23
      assert result.minute == 59
      assert result.second == 59
      assert {999_999, _precision} = result.microsecond
      assert NaiveDateTime.compare(result, naive_datetime) in [:gt, :eq]
    end
  end

  defp valid_naive_datetime?(%NaiveDateTime{
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

  defp valid_naive_datetime?(_datetime), do: false
end
