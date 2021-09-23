defmodule Tox.DateTime do
  @moduledoc """
  A set of functions to work with `DateTime`.

  All examples are using
  [`TimeZoneInfo.TimeZoneDatabase`](https://hexdocs.pm/time_zone_info/TimeZoneInfo.TimeZoneDatabase.html). But everything also works with any other time zone DB as long as the time
  zones are available in the DB.
  """

  alias Tox.IsoDays

  @utc "Etc/UTC"

  @doc """
  Shifts the `datetime` by the given `duration`.


  The `durations` is a keyword list of one or more durations of the type
  `Tox.duration` e.g. `[year: 1, day: 5, minute: 500]`. All values will be
  shifted from the largest to the smallest unit.

  ## Examples

      iex> datetime = DateTime.from_naive!(~N[1980-11-01 00:00:00], "Europe/Oslo")
      iex> Tox.DateTime.shift(datetime, year: 2)
      #DateTime<1982-11-01 00:00:00+01:00 CET Europe/Oslo>
      iex> Tox.DateTime.shift(datetime, year: -2, month: 1, hour: 48)
      #DateTime<1978-12-03 00:00:00+01:00 CET Europe/Oslo>
      iex> Tox.DateTime.shift(datetime, hour: 10, minute: 10, second: 10)
      #DateTime<1980-11-01 10:10:10+01:00 CET Europe/Oslo>

  Adding a month at the end of the month can update the day too.

      iex> datetime = DateTime.from_naive!(~N[2000-01-31 00:00:00], "Europe/Oslo")
      iex> Tox.DateTime.shift(datetime, month: 1)
      #DateTime<2000-02-29 00:00:00+01:00 CET Europe/Oslo>

  For that reason it is important to know that all values will be shifted from the
  largest to the smallest unit.

      iex> datetime = DateTime.from_naive!(~N[2000-01-30 00:00:00], "Europe/Oslo")
      iex> Tox.DateTime.shift(datetime, month: 1, day: 1)
      #DateTime<2000-03-01 00:00:00+01:00 CET Europe/Oslo>
      iex> datetime |> Tox.DateTime.shift(month: 1) |> Tox.DateTime.shift(day: 1)
      #DateTime<2000-03-01 00:00:00+01:00 CET Europe/Oslo>
      iex> datetime |> Tox.DateTime.shift(day: 1) |> Tox.DateTime.shift(month: 1)
      #DateTime<2000-02-29 00:00:00+01:00 CET Europe/Oslo>

  Treatment of time gaps. Usually, a transition to a daily-saving-time causing a time gap. For
  example, in the time-zone Europe/Berlin, the clocks are advanced by one hour on the last Sunday
  in March at 02:00. Therefore there is a gap between 02:00 and 03:00. The `shift/3` function will
  adjust this by adding or subtracting the difference from the calculated date.

      # adding a day
      iex> datetime = DateTime.from_naive!(~N[2020-03-28 02:30:00], "Europe/Berlin")
      iex> result = Tox.DateTime.shift(datetime, day: 1)
      #DateTime<2020-03-29 03:30:00+02:00 CEST Europe/Berlin>
      iex> DateTime.diff(result, datetime) == 24 * 60 * 60
      true
      iex> Tox.DateTime.shift(result, day: -1)
      #DateTime<2020-03-28 03:30:00+01:00 CET Europe/Berlin>

      # subtracting a day
      iex> datetime = DateTime.from_naive!(~N[2020-03-30 02:30:00], "Europe/Berlin")
      iex> result = Tox.DateTime.shift(datetime, day: -1)
      #DateTime<2020-03-29 01:30:00+01:00 CET Europe/Berlin>
      iex> DateTime.diff(datetime, result) == 24 * 60 * 60
      true
      iex> Tox.DateTime.shift(result, day: 1)
      #DateTime<2020-03-30 01:30:00+02:00 CEST Europe/Berlin>

  Treatment of ambiguous times. Usually, a transition from daily-saving-time causing an ambiguous
  period.  For example, in the time-zone Europe/Berlin, the clocks are set back one hour on the
  last Sunday in October. Therefore the period from 02:00 to 03:00 exists twice on this day. The
  `shift/3` function will adjust this by checking if the original datetime later or earlier.

      # adding a day
      iex> datetime = DateTime.from_naive!(~N[2020-10-24 02:30:00], "Europe/Berlin")
      iex> result = Tox.DateTime.shift(datetime, day: 1)
      #DateTime<2020-10-25 02:30:00+02:00 CEST Europe/Berlin>
      iex> DateTime.diff(result, datetime) == 24 * 60 * 60
      true

      # subtracting a day
      iex> datetime = DateTime.from_naive!(~N[2020-10-26 02:30:00], "Europe/Berlin")
      iex> result = Tox.DateTime.shift(datetime, day: -1)
      #DateTime<2020-10-25 02:30:00+01:00 CET Europe/Berlin>
      iex> DateTime.diff(datetime, result) == 24 * 60 * 60
      true

  Using `shift/3` with a different calendar.

      iex> datetime =
      ...>   ~N[2020-10-26 02:30:00]
      ...>   |> DateTime.from_naive!("Africa/Nairobi")
      ...>   |> DateTime.convert!(Cldr.Calendar.Ethiopic)
      ...>
      ...> to_string(datetime)
      "2013-02-16 02:30:00+03:00 EAT Africa/Nairobi"
      iex> datetime |> Tox.DateTime.shift(month: 13) |> to_string()
      "2014-02-16 02:30:00+03:00 EAT Africa/Nairobi"

  """
  @spec shift(Calendar.datetime(), [Tox.duration()], Calendar.time_zone_database()) ::
          DateTime.t()
  def shift(datetime, durations, time_zone_database \\ Calendar.get_time_zone_database())

  def shift(datetime, [], _time_zone_database), do: datetime

  def shift(%{time_zone: time_zone} = datetime, durations, time_zone_database) do
    with {:ok, datetime} <- shift_date(datetime, durations, time_zone_database),
         {:ok, datetime} <- DateTime.shift_zone(datetime, @utc, time_zone_database),
         {:ok, datetime} <- shift_time(datetime, durations, time_zone_database),
         {:ok, datetime} <- DateTime.shift_zone(datetime, time_zone, time_zone_database) do
      datetime
    else
      {:error, reason} ->
        raise ArgumentError,
              "cannot shift #{inspect(durations)} to #{inspect(datetime)}, " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns true if `datetime1` occurs after `datetime2`.

  ## Examples

      iex> Tox.DateTime.after?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z], "Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z], "Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.after?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z], "Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z], "Etc/UTC")
      ...> )
      false

      iex> Tox.DateTime.after?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC")
      ...> )
      false

      # with time zone Europe/London (UTC+1) and Europe/Berlin (UTC+2)
      iex> Tox.DateTime.after?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000999], "Europe/Berlin"),
      ...>   DateTime.from_naive!(~N[2020-06-14 14:01:43.000001], "Europe/London")
      ...> )
      true

  """
  defmacro after?(datetime1, datetime2) do
    quote do
      DateTime.compare(unquote(datetime1), unquote(datetime2)) == :gt
    end
  end

  @doc """
  Returns true if `datetime1` occurs after `datetime2` or both datetimes are
  equal.

  ## Examples

      iex> Tox.DateTime.after_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.after_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC" )
      ...> )
      true

      iex> Tox.DateTime.after_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC")
      ...> )
      false

      # with time zone Europe/London (UTC+1) and Europe/Berlin (UTC+2)
      iex> Tox.DateTime.after_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000999], "Europe/Berlin"),
      ...>   DateTime.from_naive!(~N[2020-06-14 14:01:43.000001], "Europe/London")
      ...> )
      true

  """
  defmacro after_or_equal?(datetime1, datetime2) do
    quote do
      DateTime.compare(unquote(datetime1), unquote(datetime2)) in [:gt, :eq]
    end
  end

  @doc """
  Returns true if both datetimes are equal.

  ## Examples

      iex> Tox.DateTime.equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC")
      ...> )
      false

      iex> Tox.DateTime.equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC")
      ...> )
      false

      # with time zone Europe/London (UTC+1) and Europe/Berlin (UTC+2)
      iex> Tox.DateTime.equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000999], "Europe/Berlin"),
      ...>   DateTime.from_naive!(~N[2020-06-14 14:01:43.000999], "Europe/London")
      ...> )
      true

  """
  defmacro equal?(datetime1, datetime2) do
    quote do
      DateTime.compare(unquote(datetime1), unquote(datetime2)) == :eq
    end
  end

  @doc """
  Returns true if `datetime1` occurs before `datetime2`.

  ## Examples

      iex> Tox.DateTime.before?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.before?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC")
      ...> )
      false

      iex> Tox.DateTime.before?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC")
      ...> )
      false

      # with time zone Europe/London (UTC+1) and Europe/Berlin (UTC+2)
      iex> Tox.DateTime.before?(
      ...>   DateTime.from_naive!(~N[2020-06-14 14:01:43.000001], "Europe/London"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000999], "Europe/Berlin")
      ...> )
      true
  """
  defmacro before?(datetime1, datetime2) do
    quote do
      DateTime.compare(unquote(datetime1), unquote(datetime2)) == :lt
    end
  end

  @doc """
  Returns true if `datetime1` occurs before `datetime2` or both datetimes are equal.

  ## Examples

      iex> Tox.DateTime.before_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.before_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43Z],"Etc/UTC")
      ...> )
      true

      iex> Tox.DateTime.before_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999Z],"Etc/UTC"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.000001Z],"Etc/UTC")
      ...> )
      false

      # with time zone Europe/London (UTC+1) and Europe/Berlin (UTC+2)
      iex> Tox.DateTime.before_or_equal?(
      ...>   DateTime.from_naive!(~N[2020-06-14 14:01:43.000000], "Europe/London"),
      ...>   DateTime.from_naive!(~N[2020-06-14 15:01:43.999999], "Europe/Berlin")
      ...> )
      true
  """
  defmacro before_or_equal?(datetime1, datetime2) do
    quote do
      DateTime.compare(unquote(datetime1), unquote(datetime2)) in [:lt, :eq]
    end
  end

  @doc """
  Returns datetime representing the start of the year.

  ## Examples

      iex> ~N[2020-11-11 11:11:11]
      iex> |> DateTime.from_naive!("Europe/Berlin")
      iex> |> Tox.DateTime.beginning_of_year()
      #DateTime<2020-01-01 00:00:00+01:00 CET Europe/Berlin>

      iex> ~N[1969-11-11 12:00:00]
      iex> |> DateTime.from_naive!("Antarctica/Casey")
      iex> |> Tox.DateTime.beginning_of_year()
      #DateTime<1969-01-01 08:00:00+08:00 +08 Antarctica/Casey>

  """
  @spec beginning_of_year(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def beginning_of_year(datetime, time_zone_database \\ Calendar.get_time_zone_database()) do
    beginning_of_day(%{datetime | month: 1, day: 1}, time_zone_database)
  end

  @doc """
  Returns datetime representing the start of the month.

  ## Examples

      iex> ~N[2020-11-11 11:11:11]
      iex> |> DateTime.from_naive!("Europe/Berlin")
      iex> |> Tox.DateTime.beginning_of_month()
      #DateTime<2020-11-01 00:00:00+01:00 CET Europe/Berlin>

      iex> ~N[1969-01-11 12:00:00]
      iex> |> DateTime.from_naive!("Antarctica/Casey")
      iex> |> Tox.DateTime.beginning_of_month()
      #DateTime<1969-01-01 08:00:00+08:00 +08 Antarctica/Casey>

  """
  @spec beginning_of_month(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def beginning_of_month(datetime, time_zone_database \\ Calendar.get_time_zone_database()) do
    beginning_of_day(%{datetime | day: 1}, time_zone_database)
  end

  @doc """
  Returns a datetime representing the start of the week.

  ## Examples

      iex> ~N[2020-07-22 11:11:11]
      iex> |> DateTime.from_naive!("Europe/Berlin")
      iex> |> Tox.DateTime.beginning_of_week()
      #DateTime<2020-07-20 00:00:00+02:00 CEST Europe/Berlin>

  """
  @spec beginning_of_week(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def beginning_of_week(
        %{calendar: calendar, time_zone: time_zone} = datetime,
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    datetime
    |> Tox.Date.beginning_of_week()
    |> to_datetime(0, time_zone, calendar, time_zone_database)
  end

  @doc """
  Returns a datetime representing the start of the day.

  ## Examples

      iex> ~N[2020-03-29 12:00:00]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.beginning_of_day()
      #DateTime<2020-03-29 00:00:00+01:00 CET Europe/Berlin>

  On a day starting with a gap

      iex> ~N[2011-04-03 12:00:00]
      iex> |> DateTime.from_naive!("Africa/El_Aaiun")
      iex> |> Tox.DateTime.beginning_of_day()
      #DateTime<2011-04-03 01:00:00+01:00 +01 Africa/El_Aaiun>

  On a day starting with an ambiguous period

      iex> datetime = DateTime.from_naive!(~N[2020-10-25 12:00:00], "America/Scoresbysund")
      #DateTime<2020-10-25 12:00:00-01:00 -01 America/Scoresbysund>
      iex> Tox.DateTime.beginning_of_day(datetime)
      #DateTime<2020-10-25 00:00:00+00:00 +00 America/Scoresbysund>

  """
  @spec beginning_of_day(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def beginning_of_day(
        %{
          time_zone: time_zone,
          calendar: calendar,
          year: year,
          month: month,
          day: day,
          microsecond: {_, precision}
        },
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    to_datetime(year, month, day, precision, time_zone, calendar, time_zone_database)
  end

  @doc """
  Returns a boolean indicating whether `datetime` occurs between `from` and `to`.
  The optional `boundaries` specifies whether `from` and `to` are included or
  not. The possible value for `boundaries` are:

  * `:open`: `from` and `to` are excluded
  * `:closed`: `from` and `to` are included
  * `:left_open`: `from` is excluded and `to` is included
  * `:right_open`: `from` is included and `to` is excluded

  ## Examples

      iex> from     = DateTime.from_naive!(~N[2020-04-05 12:30:00], "Asia/Omsk")
      iex> to       = DateTime.from_naive!(~N[2020-04-15 12:30:00], "Asia/Omsk")
      iex> datetime = DateTime.from_naive!(~N[2020-04-01 12:30:00], "Asia/Omsk")
      iex> Tox.DateTime.between?(datetime, from, to)
      false
      iex> datetime = DateTime.from_naive!(~N[2020-04-11 12:30:00], "Asia/Omsk")
      iex> Tox.DateTime.between?(datetime, from, to)
      true
      iex> datetime = DateTime.from_naive!(~N[2020-04-21 12:30:00], "Asia/Omsk")
      iex> Tox.DateTime.between?(datetime, from, to)
      false
      iex> Tox.DateTime.between?(from, from, to)
      true
      iex> Tox.DateTime.between?(to, from, to)
      false
      iex> Tox.DateTime.between?(from, from, to, :open)
      false
      iex> Tox.DateTime.between?(to, from, to, :open)
      false
      iex> Tox.DateTime.between?(from, from, to, :closed)
      true
      iex> Tox.DateTime.between?(to, from, to, :closed)
      true
      iex> Tox.DateTime.between?(from, from, to, :left_open)
      false
      iex> Tox.DateTime.between?(to, from, to, :left_open)
      true
      iex> Tox.DateTime.between?(datetime, to, from)
      ** (ArgumentError) from is equal or greater as to

  """
  @spec between?(Calendar.datetime(), Calendar.datetime(), Calendar.datetime(), Tox.boundaries()) ::
          boolean()
  def between?(datetime, from, to, boundaries \\ :right_open)
      when boundaries in [:closed, :left_open, :right_open, :open] do
    if DateTime.compare(from, to) in [:gt, :eq],
      do: raise(ArgumentError, "from is equal or greater as to")

    case {DateTime.compare(datetime, from), DateTime.compare(datetime, to), boundaries} do
      {:lt, _, _} -> false
      {_, :gt, _} -> false
      {:eq, _, :closed} -> true
      {:eq, _, :right_open} -> true
      {_, :eq, :closed} -> true
      {_, :eq, :left_open} -> true
      {:gt, :lt, _} -> true
      {_, _, _} -> false
    end
  end

  @doc """
  Returns a datetime representing the end of the year.

  ## Examples

      iex> ~N[2020-03-29 01:00:00]
      iex> |> DateTime.from_naive!("Europe/Berlin")
      iex> |> Tox.DateTime.end_of_year()
      #DateTime<2020-12-31 23:59:59.999999+01:00 CET Europe/Berlin>

  With the Ethiopic calendar.

      iex> datetime =
      ...>   ~N[2020-10-26 02:30:00]
      ...>   |> DateTime.from_naive!("Africa/Nairobi")
      ...>   |> DateTime.convert!(Cldr.Calendar.Ethiopic)
      ...>
      ...> to_string(datetime)
      "2013-02-16 02:30:00+03:00 EAT Africa/Nairobi"
      iex> datetime |> Tox.DateTime.end_of_year() |> to_string()
      "2013-13-05 23:59:59.999999+03:00 EAT Africa/Nairobi"

  """
  @spec end_of_year(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def end_of_year(
        %{calendar: calendar, year: year} = datetime,
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    month = calendar.months_in_year(year)
    day = calendar.days_in_month(year, month)
    end_of_day(%{datetime | month: month, day: day}, time_zone_database)
  end

  @doc """
  Returns a datetime} representing the end of the month.

  ## Examples

      iex> ~N[2020-11-11 11:11:11]
      ...> |> DateTime.from_naive!("Europe/Amsterdam")
      ...> |> Tox.DateTime.end_of_month()
      #DateTime<2020-11-30 23:59:59.999999+01:00 CET Europe/Amsterdam>

  """
  @spec end_of_month(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def end_of_month(
        %{calendar: calendar, year: year, month: month} = datetime,
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    day = calendar.days_in_month(year, month)
    end_of_day(%{datetime | day: day}, time_zone_database)
  end

  @doc """
  Returns a datetime representing the end of the week.

  ## Examples

      iex> ~N[2020-07-22 11:11:11]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.end_of_week()
      #DateTime<2020-07-26 23:59:59.999999+02:00 CEST Europe/Berlin>

  """
  @spec end_of_week(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def end_of_week(
        %{calendar: calendar, year: year, month: month, day: day} = datetime,
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    day = Tox.days_per_week() - Tox.day_of_week(calendar, year, month, day)

    datetime
    |> shift(day: day)
    |> end_of_day(time_zone_database)
  end

  @doc """
  Returns datetime representing the end of the day.

  ## Examples

      iex> ~N[2020-03-29 01:00:00]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.end_of_day()
      #DateTime<2020-03-29 23:59:59.999999+02:00 CEST Europe/Berlin>

  On a day ending with a gap.

      iex> ~N[1916-06-14 12:00:00]
      ...> |> DateTime.from_naive!("Africa/Algiers")
      ...> |> Tox.DateTime.end_of_day()
      #DateTime<1916-06-14 22:59:59.999999+00:00 WET Africa/Algiers>

  On a day ending with an ambiguous period.

      iex> datetime = DateTime.from_naive!(~N[1931-12-30 12:00:00], "Africa/Accra")
      #DateTime<1931-12-30 12:00:00+00:20 +0020 Africa/Accra>
      iex> Tox.DateTime.end_of_day(datetime)
      #DateTime<1931-12-30 23:59:59.999999+00:20 +0020 Africa/Accra>

  """
  @spec end_of_day(Calendar.datetime(), Calendar.time_zone_database()) :: DateTime.t()
  def end_of_day(
        %{
          time_zone: time_zone,
          calendar: calendar,
          year: year,
          month: month,
          day: day
        } = datetime,
        time_zone_database \\ Calendar.get_time_zone_database()
      ) do
    {hour, minute, second, microsecond} = Tox.Time.max_tuple(calendar)

    with {:ok, naive_datetime} <-
           NaiveDateTime.new(year, month, day, hour, minute, second, microsecond, calendar),
         {:ok, new_datetime} <- DateTime.from_naive(naive_datetime, time_zone, time_zone_database) do
      new_datetime
    else
      {:gap, new_datetime, _} ->
        new_datetime

      {:ambiguous, _, new_datetime} ->
        new_datetime

      {:error, reason} ->
        raise ArgumentError,
              "cannot set #{inspect(datetime)} to end of day, " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns an `{year, week}` representing the ISO week number for the specified
  date.

  This function is just defined for datetimes with `Calendar.ISO`.

  ## Example

      iex> ~N[2017-01-01 01:00:00]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.week()
      {2016, 52}

      iex> ~N[2020-01-01 01:00:00]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.week()
      {2020, 1}

      iex> ~N[2019-12-31 01:00:00]
      ...> |> DateTime.from_naive!("Europe/Berlin")
      ...> |> Tox.DateTime.week()
      {2020, 1}

      iex> ~N[2020-06-04 11:12:13]
      ...> |> DateTime.from_naive!("Etc/UTC")
      ...> |> DateTime.convert(Cldr.Calendar.Coptic)
      ...> |> Tox.DateTime.week()
      ** (FunctionClauseError) no function clause matching in Tox.DateTime.week/1

  """
  @spec week(Calendar.datetime()) :: {Calendar.year(), non_neg_integer}
  def week(%{calendar: Calendar.ISO} = datetime), do: Tox.week(datetime)

  ## Helpers

  defp shift_date(%{time_zone: time_zone} = datetime, durations, time_zone_database) do
    datetime
    |> Tox.Date.shift(durations)
    |> Tox.NaiveDateTime.from_date_time(datetime)
    |> adjust_datetime(datetime, time_zone, time_zone_database)
  end

  defp shift_time(
         %{calendar: calendar, microsecond: {_, precision}} = datetime,
         durations,
         time_zone_database
       ) do
    datetime
    |> IsoDays.from_datetime()
    |> IsoDays.add(IsoDays.from_durations_time(durations, calendar, precision))
    |> from_iso_days(calendar, precision, @utc, time_zone_database)
  end

  defp adjust_datetime(naive_datetime, from_datetime, time_zone, time_zone_database) do
    case time_zone_database.time_zone_periods_from_wall_datetime(naive_datetime, time_zone) do
      {:ok, _} ->
        DateTime.from_naive(naive_datetime, time_zone, time_zone_database)

      {_, _, _} = gap_or_ambiguous ->
        adjust_datetime(
          gap_or_ambiguous,
          naive_datetime,
          from_datetime,
          time_zone,
          time_zone_database
        )

      {:error, _} = error ->
        error
    end
  end

  defp adjust_datetime(
         {:gap, {%{std_offset: std_offset1, utc_offset: utc_offset1}, _},
          {%{std_offset: std_offset2, utc_offset: utc_offset2}, _}},
         naive_datetime,
         from_datetime,
         time_zone,
         time_zone_database
       ) do
    diff =
      case NaiveDateTime.compare(from_datetime, naive_datetime) do
        :gt ->
          utc_offset1 + std_offset1 - (utc_offset2 + std_offset2)

        :lt ->
          utc_offset2 + std_offset2 - (utc_offset1 + std_offset1)
      end

    naive_datetime
    |> NaiveDateTime.add(diff)
    |> DateTime.from_naive(time_zone, time_zone_database)
  end

  defp adjust_datetime(
         {:ambiguous, _, _},
         naive_datetime,
         from_datetime,
         time_zone,
         time_zone_database
       ) do
    case {NaiveDateTime.compare(from_datetime, naive_datetime),
          DateTime.from_naive(naive_datetime, time_zone, time_zone_database)} do
      {:eq, _} -> {:ok, from_datetime}
      {:lt, {:ambiguous, datetime, _}} -> {:ok, datetime}
      {:gt, {:ambiguous, _, datetime}} -> {:ok, datetime}
    end
  end

  {:ambiguous,
   %{
     std_offset: 3600,
     utc_offset: 3600,
     wall_period: {~N[2019-03-31 03:00:00], ~N[2019-10-27 03:00:00]},
     zone_abbr: "CEST"
   },
   %{
     std_offset: 0,
     utc_offset: 3600,
     wall_period: {~N[2019-10-27 02:00:00], ~N[2020-03-29 02:00:00]},
     zone_abbr: "CET"
   }}

  defp from_iso_days(iso_days, calendar, precision, time_zone, time_zone_database) do
    iso_days
    |> Tox.NaiveDateTime.from_iso_days(calendar, precision)
    |> DateTime.from_naive(time_zone, time_zone_database)
  end

  defp to_datetime(
         %{year: year, month: month, day: day},
         precision,
         time_zone,
         calendar,
         time_zone_database
       ) do
    to_datetime(year, month, day, precision, time_zone, calendar, time_zone_database)
  end

  defp to_datetime(year, month, day, precision, time_zone, calendar, time_zone_database) do
    with {:ok, naive_datetime} <-
           NaiveDateTime.new(year, month, day, 0, 0, 0, {0, precision}, calendar),
         {:ok, datetime} <-
           DateTime.from_naive(naive_datetime, time_zone, time_zone_database) do
      datetime
    else
      {:gap, _, datetime} ->
        datetime

      {:ambiguous, datetime, _} ->
        %{
          datetime
          | year: year,
            month: month,
            day: day,
            hour: 0,
            minute: 0,
            second: 0,
            microsecond: {0, 0}
        }

      {:error, reason} ->
        raise ArgumentError,
              "cannot set #{year}-#{month}-#{day} to beginning of day, " <>
                "reason: #{inspect(reason)}"
    end
  end
end
