defmodule Tox do
  @moduledoc """
  Some structs and functions to work with dates, times, durations, periods, and
  intervals.
  """

  @typedoc """
  Units related to dates and times.
  """
  @type unit ::
          :year
          | :month
          | :week
          | :day
          | :hour
          | :minute
          | :second
          | :microsecond

  @typedoc """
  An amount of time with a specified unit e.g. `{second: 500}`.
  """
  @type duration :: {unit(), integer()}

  @typedoc """
  Boundaries specifies whether the start and end of an interval are included or
  excluded.

  * `:open`: start and end are excluded
  * `:closed`: start and end are included
  * `:left_open`: start is excluded and end is included
  * `:right_open`: start is included and end is excluded
  """
  @type boundaries :: :closed | :left_open | :right_open | :open

  @doc """
  Shift the `DateTime`, `NaiveDateTime`, `Date` or `Time` by the given duration.
  """
  @spec shift(date_or_time, [duration()]) :: date_or_time
        when date_or_time: DateTime.t() | NaiveDateTime.t() | Date.t() | Time.t()
  def shift(%DateTime{} = datetime, duration), do: Tox.DateTime.shift(datetime, duration)
  def shift(%NaiveDateTime{} = naive, duration), do: Tox.NaiveDateTime.shift(naive, duration)
  def shift(%Date{} = date, duration), do: Tox.Date.shift(date, duration)
  def shift(%Time{} = time, duration), do: Tox.Time.shift(time, duration)

  @doc false
  @spec days_per_week :: integer()
  def days_per_week, do: 7

  @doc false
  @spec week(Calendar.date()) :: {Calendar.year(), non_neg_integer()}
  def week(%{calendar: Calendar.ISO, year: year, month: month, day: day}) do
    :calendar.iso_week_number({year, month, day})
  end

  if function_exported?(Date, :day_of_week, 2) do
    @doc false
    @spec day_of_week(Calendar.calendar(), integer(), non_neg_integer, non_neg_integer) :: 1..7
    def day_of_week(calendar, year, month, day) do
      {day, _epoch_day_of_week, _last_day_of_week} =
        calendar.day_of_week(year, month, day, :default)

      day
    end
  else
    @doc false
    @spec day_of_week(Calendar.calendar(), integer(), non_neg_integer, non_neg_integer) :: 1..7
    def day_of_week(calendar, year, month, day) do
      calendar.day_of_week(year, month, day)
    end
  end
end
