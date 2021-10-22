# Tox
[![Hex.pm: version](https://img.shields.io/hexpm/v/tox.svg?style=flat-square)](https://hex.pm/packages/tox)
[![GitHub: CI status](https://img.shields.io/github/workflow/status/hrzndhrn/tox/CI?style=flat-square)](https://github.com/hrzndhrn/tox/actions)
[![Coveralls: coverage](https://img.shields.io/coveralls/github/hrzndhrn/tox?style=flat-square)](https://coveralls.io/github/hrzndhrn/tox)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hrzndhrn/tox/blob/main/LICENSE.md)

Some structs and functions to work with dates, times, periods, and intervals.

`Tox` needs Elixir 1.8 or greater. The library works with any
[`Calendar.time_zone_database`](https://hexdocs.pm/elixir/Calendar.html#t:time_zone_database/0)
and any [`Calendar`](https://hexdocs.pm/elixir/Calendar.html#content).

The tests and examples are using the time zone database from
[`TimeZoneInfo`](https://github.com/hrzndhrn/time_zone_info)
and the calendars
[`Calendar.ISO`](https://hexdocs.pm/elixir/Calendar.ISO.html#content),
[`Cldr.Calendar.Coptic`](https://github.com/elixir-cldr/cldr_calendars_coptic)
and
[`Cldr.Calendar.Ethiopic`](https://github.com/elixir-cldr/cldr_calendars_ethiopic).

## Installation

The package can be installed by adding `tox` to your list of dependencies in
mix.exs. Fox time zone support you can install `time_zone_info`, `tz`, or
`tzdata`.

```elixir
def deps do
  [
    {:tox, "~> 0.2"}
    # add one of the following packages for time zone support
    # {:time_zone_info, "~> 0.5"}
    # {:tz, "~> 0.10"}
    # {:tzdata, "~> 1.0"}
  ]
end
```

## Notes

`Tox` assumes that a week consists of 7 days. This assumption is not true for all
calendars.

The functions `Tox.DateTime.week/1`, `Tox.NaiveDateTime.week/1`, and
`Tox.Date.week/1` are just defined for `Calendar.ISO`.
This functions are returning a tuple of the year and the week number.

## Usage

Some examples how to use `Tox`.  For more information and examples, see
[`API reference`](https://hexdocs.pm/tox/api-reference.html#content).

before and after:
```elixir
iex> datetime = DateTime.from_naive!(~N[2020-03-10 12:00:00], "Europe/Berlin")
iex> Tox.DateTime.before?(datetime, Tox.DateTime.shift(datetime, day: 1))
true
iex> Tox.DateTime.before_or_equal?(datetime, datetime)
true
iex> Tox.DateTime.after?(datetime, Tox.DateTime.shift(datetime, day: 1))
false
```

shifting back and forward:
```elixir
iex> datetime = DateTime.from_naive!(~N[2020-01-01 12:00:00], "Europe/Oslo")
iex> Tox.DateTime.shift(datetime, year: 2, month: -3, day: 2, hour: -24, minute: 10)
#DateTime<2021-10-02 12:10:00+02:00 CEST Europe/Oslo>

iex> naive_datetime = ~N[2020-01-01 12:00:00]
iex> Tox.NaiveDateTime.shift(naive_datetime, year: 2, month: -3, day: 2, hour: -24, minute: 10)
~N[2021-10-02 12:10:00+02:00]

iex> Tox.Date.shift(~D[2020-01-01], year: 2, month: -3, day: 2)
~D[2021-10-03]

iex> Tox.Time.shift(~T[00:00:00], hour: 2, minute: -10, microsecond: 99)
~T[01:50:00.000099]

iex> {:ambiguous, datetime1, datetime2} =
...>   DateTime.from_naive(~N[2020-10-25 02:30:00], "Europe/Oslo")
iex> Tox.DateTime.shift(datetime1, hour: 1) == datetime2
true

# falling into a gap
iex> datetime = DateTime.from_naive!(~N[2020-03-29 01:30:00], "Europe/Paris")
#DateTime<2020-03-29 01:30:00+01:00 CET Europe/Paris>
iex> Tox.DateTime.shift(datetime, minute: 40)
#DateTime<2020-03-29 03:10:00+02:00 CEST Europe/Paris>
```

period and interval:
```elixir
iex> now = DateTime.from_naive!(~N[2020-07-12 21:33:43], "America/New_York")
iex> period = Tox.Period.new!(month: 1)
#Tox.Period<P1M>
iex> interval = Tox.Interval.new!(Tox.DateTime.beginning_of_month(now), period)
#Tox.Interval<[2020-07-01T00:00:00-04:00/P1M[>
iex> Tox.Interval.contains?(interval, now)
true
iex> Tox.Interval.since_start(interval, now, :millisecond)
{:ok, 1028023000}
iex> Tox.Interval.until_ending(interval, now, :millisecond)
{:ok, 1650377000}
iex> Tox.Interval.until_ending(interval, Tox.DateTime.shift(now, month: 1), :millisecond)
:error
```

beginning and end of
```elixir
iex> ~N[2020-07-12 11:12:13]
...> |> DateTime.from_naive!("America/Winnipeg")
...> |> Tox.DateTime.beginning_of_year()
#DateTime<2020-01-01 00:00:00-06:00 CST America/Winnipeg>

iex> ~N[2020-07-12 11:12:13]
...> |> DateTime.from_naive!("Europe/Berlin")
...> |> Tox.DateTime.end_of_year()
#DateTime<2020-12-31 23:59:59.999999+01:00 CET Europe/Berlin>

# In 1994 the year ended one day earlier in the time zone Pacific/Kirimati.
iex> ~N[1994-07-12 11:12:13]
...> |> DateTime.from_naive!("Pacific/Kiritimati")
...> |> Tox.DateTime.end_of_year()
#DateTime<1994-12-30 23:59:59.999999-10:00 -10 Pacific/Kiritimati>

iex> Tox.NaiveDateTime.beginning_of_day(~N[2020-01-01 12:00:00])
~N[2020-01-01 00:00:00]

iex> Tox.NaiveDateTime.end_of_day(~N[2020-01-01 12:00:00])
~N[2020-01-01 23:59:59.999999]

iex> Tox.Date.beginning_of_week(~D[2020-01-10])
~D[2020-01-06]

iex> Tox.Date.end_of_week(~D[2020-01-10])
~D[2020-01-12]
```
