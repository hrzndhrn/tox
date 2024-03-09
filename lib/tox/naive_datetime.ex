defmodule Tox.NaiveDateTime do
  @moduledoc """
  A set of functions to work with `NaiveDateTime`.
  """

  alias Tox.IsoDays

  @doc """
  Shifts the `naive_datetime` by the given `duration`.


  The `durations` is a keyword list of one or more durations of the type
  `Tox.duration` e.g. `[year: 1, day: 5, minute: 500]`. All values will be
  shifted from the largest to the smallest unit.

  ## Examples

      iex> naive_datetime = ~N[2000-01-01 00:00:00]
      iex> Tox.NaiveDateTime.shift(naive_datetime, year: 2)
      ~N[2002-01-01 00:00:00]
      iex> Tox.NaiveDateTime.shift(naive_datetime, year: -2, month: 1, hour: 48)
      ~N[1998-02-03 00:00:00]
      iex> Tox.NaiveDateTime.shift(naive_datetime, hour: 10, minute: 10, second: 10)
      ~N[2000-01-01 10:10:10]

  Adding a month at the end of the month can update the day too.

      iex> Tox.NaiveDateTime.shift(~N[2000-01-31 00:00:00], month: 1)
      ~N[2000-02-29 00:00:00]

  For that reason it is important to know that all values will be shifted from the
  largest to the smallest unit.

      iex> naive_datetime = DateTime.from_naive!(~N[2000-01-30 00:00:00], "Europe/Oslo")
      iex> Tox.NaiveDateTime.shift(naive_datetime, month: 1, day: 1)
      ~N[2000-03-01 00:00:00+01:00]
      iex> naive_datetime |> Tox.NaiveDateTime.shift(month: 1) |> Tox.NaiveDateTime.shift(day: 1)
      ~N[2000-03-01 00:00:00+01:00]
      iex> naive_datetime |> Tox.NaiveDateTime.shift(day: 1) |> Tox.NaiveDateTime.shift(month: 1)
      ~N[2000-02-29 00:00:00+01:00]

  Using `shift/2` with a different calendar.

      iex> ~N[2012-09-03 02:30:00]
      ...> |> NaiveDateTime.convert!(Calendar.Holocene)
      ...> |> Tox.NaiveDateTime.shift(day: 6)
      %NaiveDateTime{
        calendar: Calendar.Holocene,
        year: 12012,
        month: 9,
        day: 9,
        hour: 2,
        minute: 30,
        second: 0,
        microsecond: {0, 0}
      }

  """
  @spec shift(Calendar.naive_datetime(), [Tox.duration()]) :: NaiveDateTime.t()
  def shift(
        %{calendar: calendar, microsecond: {_microsecond, precision}} = naive_datetime,
        durations
      ) do
    naive_datetime
    |> Tox.Date.shift(durations)
    |> from_date_time(naive_datetime)
    |> IsoDays.from_naive_datetime()
    |> IsoDays.add(IsoDays.from_durations_time(durations, calendar, precision))
    |> from_iso_days(calendar, precision)
  end

  @doc """
  Returns true if `naive_datetime1` occurs after `naive_datetime2`.

  ## Examples

      iex> Tox.NaiveDateTime.after?(
      ...>   ~N[2020-06-14 15:01:43.999999],
      ...>   ~N[2020-06-14 15:01:43.000001]
      ...> )
      true

      iex> Tox.NaiveDateTime.after?(
      ...>   ~N[2020-06-14 15:01:43],
      ...>   ~N[2020-06-14 15:01:43]
      ...> )
      false

      iex> Tox.NaiveDateTime.after?(
      ...>   ~N[2020-06-14 15:01:43.000001],
      ...>   ~N[2020-06-14 15:01:43.999999]
      ...> )
      false

  """
  @spec after?(Calendar.naive_datetime(), Calendar.naive_datetime()) :: boolean()
  def after?(naive_datetime1, naive_datetime2) do
    NaiveDateTime.compare(naive_datetime1, naive_datetime2) == :gt
  end

  @doc """
  Returns true if `naive_datetime1` occurs after `naive_datetime2` or both naive
  datetimes are equal.

  ## Examples

      iex> Tox.NaiveDateTime.after_or_equal?(
      ...>   ~N[2020-06-14 15:01:43.999999],
      ...>   ~N[2020-06-14 15:01:43.000001]
      ...> )
      true

      iex> Tox.NaiveDateTime.after_or_equal?(
      ...>   ~N[2020-06-14 15:01:43],
      ...>   ~N[2020-06-14 15:01:43]
      ...> )
      true

      iex> Tox.NaiveDateTime.after_or_equal?(
      ...>   ~N[2020-06-14 15:01:43.000001],
      ...>   ~N[2020-06-14 15:01:43.999999]
      ...> )
      false

  """
  @spec after_or_equal?(Calendar.naive_datetime(), Calendar.naive_datetime()) :: boolean()
  def after_or_equal?(naive_datetime1, naive_datetime2) do
    NaiveDateTime.compare(naive_datetime1, naive_datetime2) in [:gt, :eq]
  end

  @doc """
  Returns true if both naive datetimes are equal.

  ## Examples

      iex> Tox.NaiveDateTime.equal?(
      ...>   ~N[2020-06-14 15:01:43.999999],
      ...>   ~N[2020-06-14 15:01:43.000001]
      ...> )
      false

      iex> Tox.NaiveDateTime.equal?(
      ...>   ~N[2020-06-14 15:01:43],
      ...>   ~N[2020-06-14 15:01:43]
      ...> )
      true

      iex> Tox.NaiveDateTime.equal?(
      ...>   ~N[2020-06-14 15:01:43.000001],
      ...>   ~N[2020-06-14 15:01:43.999999]
      ...> )
      false

  """
  @spec equal?(Calendar.naive_datetime(), Calendar.naive_datetime()) :: boolean()
  def equal?(naive_datetime1, naive_datetime2) do
    NaiveDateTime.compare(naive_datetime1, naive_datetime2) == :eq
  end

  @doc """
  Returns true if `naive_datetime1` occurs before `naive_datetime2`.

  ## Examples

      iex> Tox.NaiveDateTime.before?(
      ...>   ~N[2020-06-14 15:01:43.000001],
      ...>   ~N[2020-06-14 15:01:43.999999]
      ...> )
      true

      iex> Tox.NaiveDateTime.before?(
      ...>   ~N[2020-06-14 15:01:43],
      ...>   ~N[2020-06-14 15:01:43]
      ...> )
      false

      iex> Tox.NaiveDateTime.before?(
      ...>   ~N[2020-06-14 15:01:43.999999],
      ...>   ~N[2020-06-14 15:01:43.000001]
      ...> )
      false

  """
  @spec before?(Calendar.naive_datetime(), Calendar.naive_datetime()) :: boolean()
  def before?(naive_datetime1, naive_datetime2) do
    NaiveDateTime.compare(naive_datetime1, naive_datetime2) == :lt
  end

  @doc """
  Returns true if `naive_datetime1` occurs before `naive_datetime2` or both
  naive datetimes are equal.

  ## Examples

      iex> Tox.NaiveDateTime.before_or_equal?(
      ...>   ~N[2020-06-14 15:01:43.000001],
      ...>   ~N[2020-06-14 15:01:43.999999]
      ...> )
      true

      iex> Tox.NaiveDateTime.before_or_equal?(
      ...>   ~N[2020-06-14 15:01:43],
      ...>   ~N[2020-06-14 15:01:43]
      ...> )
      true

      iex> Tox.NaiveDateTime.before_or_equal?(
      ...>   ~N[2020-06-14 15:01:43.999999],
      ...>   ~N[2020-06-14 15:01:43.000001]
      ...> )
      false

  """
  @spec before_or_equal?(Calendar.naive_datetime(), Calendar.naive_datetime()) :: boolean()
  def before_or_equal?(naive_datetime1, naive_datetime2) do
    NaiveDateTime.compare(naive_datetime1, naive_datetime2) in [:lt, :eq]
  end

  @doc """
  Returns a naive datetime representing the start of the year.

  ## Examples

      iex> Tox.NaiveDateTime.beginning_of_year(~N[2020-11-11 11:11:11])
      ~N[2020-01-01 00:00:00]

  """
  @spec beginning_of_year(Calendar.naive_datetime()) :: Calendar.naive_datetime()
  def beginning_of_year(naive_datetime),
    do: beginning_of_day(%{naive_datetime | month: 1, day: 1})

  @doc """
  Returns a naive datetime representing the start of the month.

  ## Examples

      iex> Tox.NaiveDateTime.beginning_of_month(~N[2020-11-11 11:11:11])
      ~N[2020-11-01 00:00:00]

  """
  @spec beginning_of_month(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def beginning_of_month(naive_datetime) do
    beginning_of_day(%{naive_datetime | day: 1})
  end

  @doc """
  Returns a naive datetime representing the start of the week.

  ## Examples

      iex> Tox.NaiveDateTime.beginning_of_week(~N[2020-07-22 11:11:11])
      ~N[2020-07-20 00:00:00]

  """
  @spec beginning_of_week(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def beginning_of_week(%{calendar: calendar} = naive_datetime) do
    naive_datetime
    |> Date.beginning_of_week()
    |> NaiveDateTime.new!(Tox.Time.min(calendar))
  end

  @doc """
  Returns a naive datetime} representing the start of the day.

  ## Examples

      iex> Tox.NaiveDateTime.beginning_of_day(~N[2020-03-29 13:00:00.123456])
      ~N[2020-03-29 00:00:00.000000]

  """
  @spec beginning_of_day(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def beginning_of_day(
        %{
          calendar: calendar,
          year: year,
          month: month,
          day: day,
          microsecond: {_microsecond, precision}
        } = naive_datetime
      ) do
    case NaiveDateTime.new(year, month, day, 0, 0, 0, {0, precision}, calendar) do
      {:ok, new_naive_datetime} ->
        new_naive_datetime

      {:error, reason} ->
        raise ArgumentError,
              "cannot set #{inspect(naive_datetime)} to beginning of day, " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns a boolean indicating whether `naive_datetime` occurs between `from`
  and `to`. The optional `boundaries` specifies whether `from` and `to` are
  included or not. The possible value for `boundaries` are:

  * `:open`: `from` and `to` are excluded
  * `:closed`: `from` and `to` are included
  * `:left_open`: `from` is excluded and `to` is included
  * `:right_open`: `from` is included and `to` is excluded

  ## Examples

      iex> from     = ~N[2020-04-05 12:30:00]
      iex> to       = ~N[2020-04-15 12:30:00]
      iex> Tox.NaiveDateTime.between?(~N[2020-04-01 12:00:00], from, to)
      false
      iex> Tox.NaiveDateTime.between?(~N[2020-04-11 12:30:00], from, to)
      true
      iex> Tox.NaiveDateTime.between?(~N[2020-04-21 12:30:00], from, to)
      false
      iex> Tox.NaiveDateTime.between?(from, from, to)
      true
      iex> Tox.NaiveDateTime.between?(to, from, to)
      false
      iex> Tox.NaiveDateTime.between?(from, from, to, :open)
      false
      iex> Tox.NaiveDateTime.between?(to, from, to, :open)
      false
      iex> Tox.NaiveDateTime.between?(from, from, to, :closed)
      true
      iex> Tox.NaiveDateTime.between?(to, from, to, :closed)
      true
      iex> Tox.NaiveDateTime.between?(from, from, to, :left_open)
      false
      iex> Tox.NaiveDateTime.between?(to, from, to, :left_open)
      true
      iex> Tox.NaiveDateTime.between?(~N[1900-01-01 00:00:00], to, from)
      ** (ArgumentError) from is equal or greater as to

  """
  @spec between?(
          Calendar.naive_datetime(),
          Calendar.naive_datetime(),
          Calendar.naive_datetime(),
          Tox.boundaries()
        ) ::
          boolean()
  def between?(naive_datetime, from, to, boundaries \\ :right_open)
      when boundaries in [:closed, :left_open, :right_open, :open] do
    if NaiveDateTime.compare(from, to) in [:gt, :eq],
      do: raise(ArgumentError, "from is equal or greater as to")

    case {
      NaiveDateTime.compare(naive_datetime, from),
      NaiveDateTime.compare(naive_datetime, to),
      boundaries
    } do
      {:lt, _to, _boundaries} -> false
      {_from, :gt, _boundaries} -> false
      {:eq, _to, :closed} -> true
      {:eq, _to, :right_open} -> true
      {_from, :eq, :closed} -> true
      {_from, :eq, :left_open} -> true
      {:gt, :lt, _boundaries} -> true
      {_from, _to, _boundaries} -> false
    end
  end

  @doc """
  Returns a naive datetime representing the end of the year.

  ## Examples

      iex> Tox.NaiveDateTime.end_of_year(~N[2020-03-29 01:00:00])
      ~N[2020-12-31 23:59:59.999999]

  With the Holocene calendar.

      iex> naive_datetime = NaiveDateTime.convert!(~N[2020-10-26 02:30:00], Calendar.Holocene)
      iex> to_string(naive_datetime)
      "12020-10-26 02:30:00"
      iex> naive_datetime |> Tox.NaiveDateTime.end_of_year() |> to_string()
      "12020-12-31 23:59:59.999999"

  """
  @spec end_of_year(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def end_of_year(%{calendar: calendar, year: year} = naive_datetime) do
    month = calendar.months_in_year(year)
    day = calendar.days_in_month(year, month)
    end_of_day(%{naive_datetime | month: month, day: day})
  end

  @doc """
  Returns a datetime} representing the end of the month.

  ## Examples

      iex> Tox.NaiveDateTime.end_of_month(~N[2020-11-11 11:11:11])
      ~N[2020-11-30 23:59:59.999999]

  """
  @spec end_of_month(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def end_of_month(%{calendar: calendar, year: year, month: month} = naive_datetime) do
    day = calendar.days_in_month(year, month)
    end_of_day(%{naive_datetime | day: day})
  end

  @doc """
  Returns a datetime representing the end of the week.

  ## Examples

      iex> Tox.NaiveDateTime.end_of_week(~N[2020-07-22 11:11:11])
      ~N[2020-07-26 23:59:59.999999]

  """
  @spec end_of_week(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def end_of_week(%{calendar: calendar, year: year, month: month, day: day} = naive_datetime) do
    day = Tox.days_per_week() - Tox.day_of_week(calendar, year, month, day)

    naive_datetime
    |> shift(day: day)
    |> end_of_day()
  end

  @doc """
  Returns datetime representing the end of the day.

  ## Examples

      iex> Tox.NaiveDateTime.end_of_day(~N[2020-03-29 01:00:00])
      ~N[2020-03-29 23:59:59.999999]

  """
  @spec end_of_day(Calendar.naive_datetime()) :: NaiveDateTime.t()
  def end_of_day(%{calendar: calendar, year: year, month: month, day: day} = naive_datetime) do
    {hour, minute, second, microsecond} = Tox.Time.max_tuple(calendar)

    case NaiveDateTime.new(year, month, day, hour, minute, second, microsecond, calendar) do
      {:ok, new_naive_datetime} ->
        new_naive_datetime

      {:error, reason} ->
        raise ArgumentError,
              "cannot set #{inspect(naive_datetime)} to end of day, " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns an `{year, week}` representing the ISO week number for the specified
  date.

  This function is just defined for datetimes with `Calendar.ISO`.

  ## Example

      iex> Tox.NaiveDateTime.week(~N[2017-01-01 01:00:00])
      {2016, 52}
      iex> Tox.NaiveDateTime.week(~N[2019-12-31 01:00:00])
      {2020, 1}
      iex> Tox.NaiveDateTime.week(~N[2020-01-01 01:00:00])
      {2020, 1}

      iex> ~N[2020-06-04 11:12:13]
      ...> |> NaiveDateTime.convert(Calendar.Holocene)
      ...> |> Tox.NaiveDateTime.week()
      ** (FunctionClauseError) no function clause matching in Tox.NaiveDateTime.week/1

  """
  @spec week(Calendar.datetime()) :: {Calendar.year(), non_neg_integer}
  def week(%{calendar: Calendar.ISO} = naive_datetime), do: Tox.week(naive_datetime)

  ## Helpers

  @doc false
  @spec from_date_time(Calendar.date(), Calendar.time()) :: NaiveDateTime.t()
  def from_date_time(
        %{calendar: calendar, year: year, month: month, day: day},
        %{
          calendar: calendar,
          hour: hour,
          minute: minute,
          second: second,
          microsecond: microsecond
        }
      ) do
    {:ok, naive_datetime} =
      NaiveDateTime.new(year, month, day, hour, minute, second, microsecond, calendar)

    naive_datetime
  end

  @doc false
  @spec from_iso_days(Calendar.iso_days(), Calendar.calendar(), non_neg_integer) ::
          NaiveDateTime.t()
  def from_iso_days(iso_days, calendar, precision) do
    {year, month, day, hour, minute, second, {microsecond, _precision}} =
      calendar.naive_datetime_from_iso_days(iso_days)

    %NaiveDateTime{
      calendar: calendar,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      microsecond: {microsecond, precision}
    }
  end
end
