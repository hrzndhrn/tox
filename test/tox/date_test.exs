defmodule Tox.DateTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Tox.Date

  describe "shift/2" do
    test "adds a year" do
      assert Tox.Date.shift(~D[1999-01-15], year: 1) == ~D[2000-01-15]
    end

    test "adds a year and updates day" do
      assert Tox.Date.shift(~D[2000-02-29], year: 1) == ~D[2001-02-28]
    end

    test "adds a month" do
      assert Tox.Date.shift(~D[2000-01-01], month: 1) == ~D[2000-02-01]
    end

    test "adds a month and updates day" do
      assert Tox.Date.shift(~D[2000-01-31], month: 1) == ~D[2000-02-29]
    end

    test "adds multiple months" do
      assert Tox.Date.shift(~D[2000-01-31], month: 2) == ~D[2000-03-31]
      assert Tox.Date.shift(~D[2000-01-31], month: 11) == ~D[2000-12-31]
      assert Tox.Date.shift(~D[2000-01-31], month: 12) == ~D[2001-01-31]
    end

    test "adds multiple months and updates day" do
      assert Tox.Date.shift(~D[2000-01-31], month: 13) == ~D[2001-02-28]
    end

    test "adds a day" do
      assert Tox.Date.shift(~D[2000-01-01], day: 1) == ~D[2000-01-02]
    end

    test "adds multiple days and updates month and year" do
      assert Tox.Date.shift(~D[2000-01-01], day: 450) == ~D[2001-03-26]
    end

    test "adds years, months, and days" do
      assert Tox.Date.shift(~D[2000-01-01], year: 2, month: 3, day: 4) == ~D[2002-04-05]
    end

    test "adds a week" do
      assert Tox.Date.shift(~D[2020-01-30], week: 1) == ~D[2020-02-06]
    end

    test "adds from the largest to the smallest unit" do
      date = ~D[2001-02-28]

      assert Tox.Date.shift(date, month: 1, day: 1) == ~D[2001-03-29]

      assert Tox.Date.shift(date, month: 1, day: 1) ==
               date |> Tox.Date.shift(month: 1) |> Tox.Date.shift(day: 1)

      assert date |> Tox.Date.shift(month: 1) |> Tox.Date.shift(day: 1) !=
               date |> Tox.Date.shift(day: 1) |> Tox.Date.shift(month: 1)
    end
  end

  property "add/2" do
    check all date <- Generator.date(),
              durations <- Generator.durations() do
      assert valid_date?(Tox.Date.shift(date, durations))
    end
  end

  property "beginning_of_month/1" do
    check all date <- Generator.date() do
      assert %Date{} = result = Tox.Date.beginning_of_month(date)
      assert result.year == date.year
      assert result.month == date.month
      assert result.day == 1
      assert Date.compare(result, date) in [:lt, :eq]
    end
  end

  property "beginning_of_week/1" do
    check all %{calendar: calendar} = date <- Generator.date() do
      assert %Date{} = result = Tox.Date.beginning_of_week(date)

      year_range = (date.year - 1)..date.year

      months = calendar.months_in_year(date.year)

      month_range =
        months..1
        |> Stream.cycle()
        |> Enum.slice(months - date.month, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert calendar.day_of_week(result.year, result.month, result.day) == 1
      assert Date.compare(result, date) in [:lt, :eq]
    end
  end

  property "beginning_of_year/1" do
    check all date <- Generator.date() do
      assert %Date{} = result = Tox.Date.beginning_of_year(date)
      assert result.year == date.year
      assert result.month == 1
      assert result.day == 1
      assert Date.compare(result, date) in [:lt, :eq]
    end
  end

  property "end_of_month/1" do
    check all %{calendar: calendar} = date <- Generator.date() do
      assert %Date{} = result = Tox.Date.end_of_month(date)
      assert result.year == date.year
      assert result.month == date.month
      assert result.day == calendar.days_in_month(result.year, result.month)
      assert Date.compare(result, date) in [:gt, :eq]
    end
  end

  property "end_of_week/1" do
    check all %{calendar: calendar} = date <- Generator.date() do
      assert %Date{} = result = Tox.Date.end_of_week(date)

      year_range = date.year..(date.year + 1)

      months = calendar.months_in_year(date.year)

      month_range =
        1..months
        |> Stream.cycle()
        |> Enum.slice(date.month - 1, 3)

      day_range = 1..31

      assert result.year in year_range
      assert result.month in month_range
      assert result.day in day_range
      assert calendar.day_of_week(result.year, result.month, result.day) == 7
      assert Date.compare(result, date) in [:gt, :eq]
    end
  end

  property "end_of_year/1" do
    check all %{calendar: calendar} = date <- Generator.date() do
      months = calendar.months_in_year(date.year)

      assert %Date{} = result = Tox.Date.end_of_year(date)
      assert result.year == date.year
      assert result.month == months
      assert result.day == calendar.days_in_month(date.year, months)
      assert Date.compare(result, date) in [:gt, :eq]
    end
  end

  defp valid_date?(%Date{calendar: calendar, year: year, month: month, day: day}) do
    calendar.valid_date?(year, month, day)
  end

  defp valid_date?(_datetime), do: false
end
