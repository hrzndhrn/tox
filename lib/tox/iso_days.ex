defmodule Tox.IsoDays do
  @moduledoc false

  @spec add(Calendar.iso_days(), Calendar.iso_days()) :: Calendar.iso_days()
  def add(
        {days1, {parts_in_day1, parts_per_day}},
        {days2, {parts_in_day2, parts_per_day}}
      ) do
    adjust({days1 + days2, {parts_in_day1 + parts_in_day2, parts_per_day}})
  end

  @spec from_datetime(Calendar.datetime()) :: Calendar.iso_days()
  def from_datetime(datetime), do: from(datetime)

  @spec from_naive_datetime(Calendar.naive_datetime()) :: Calendar.iso_days()
  def from_naive_datetime(naive_datetime), do: from(naive_datetime)

  @spec from_durations_time([Tox.duration()], Calendar.calendar(), non_neg_integer) ::
          Calendar.iso_days()
  def from_durations_time(durations, calendar, precision) do
    # Unlike the other from_* functions, this function can also return negative
    # values or values greater as parts_per_day for parts_in_day.
    {0,
     calendar.time_to_day_fraction(
       Keyword.get(durations, :hour, 0),
       Keyword.get(durations, :minute, 0),
       Keyword.get(durations, :second, 0),
       {
         Keyword.get(durations, :microsecond, 0) +
           Keyword.get(durations, :millisecond, 0) * 1_000,
         precision
       }
     )}
  end

  # Helper

  defp adjust({days, {parts_in_day, parts_per_day}}) when parts_in_day < 0 do
    quotient = div(parts_in_day, parts_per_day)
    remainder = rem(parts_in_day, parts_per_day)

    case remainder == 0 do
      true -> {days + quotient, {0, parts_per_day}}
      false -> {days + quotient - 1, {parts_per_day + remainder, parts_per_day}}
    end
  end

  defp adjust({days, {parts_in_day, parts_per_day}}) do
    {days + div(parts_in_day, parts_per_day), {rem(parts_in_day, parts_per_day), parts_per_day}}
  end

  defp from(%{
         calendar: calendar,
         year: year,
         month: month,
         day: day,
         hour: hour,
         minute: minute,
         second: second,
         microsecond: microsecond
       }) do
    calendar.naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond)
  end
end
