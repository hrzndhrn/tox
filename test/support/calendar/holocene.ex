defmodule Calendar.Holocene do
  # This calendar is used for tests with an none ISO calendar.
  # It implements the Holocene calendar, which is based on the
  # Proleptic Gregorian calendar with every year + 10_000.

  @behaviour Calendar

  def date(year, month, day) do
    %Date{year: year, month: month, day: day, calendar: __MODULE__}
  end

  def naive_datetime(year, month, day, hour, minute, second, microsecond \\ {0, 0}) do
    %NaiveDateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      microsecond: microsecond,
      calendar: __MODULE__
    }
  end

  def date_to_string(year, month, day) do
    "#{year}-#{zero_pad(month, 2)}-#{zero_pad(day, 2)}"
  end

  def naive_datetime_to_string(year, month, day, hour, minute, second, microsecond) do
    "#{year}-#{zero_pad(month, 2)}-#{zero_pad(day, 2)} " <>
      Calendar.ISO.time_to_string(hour, minute, second, microsecond)
  end

  def datetime_to_string(
        year,
        month,
        day,
        hour,
        minute,
        second,
        microsecond,
        time_zone,
        zone_abbr,
        utc_offset,
        std_offset
      ) do
    "#{year}-#{zero_pad(month, 2)}-#{zero_pad(day, 2)} " <>
      Calendar.ISO.time_to_string(hour, minute, second, microsecond, :extended) <>
      Calendar.ISO.offset_to_string(utc_offset, std_offset, time_zone, :extended) <>
      zone_to_string(utc_offset, std_offset, zone_abbr, time_zone)
  end

  defp zone_to_string(_, _, _, "Etc/UTC"), do: ""
  defp zone_to_string(_, _, abbr, zone), do: " " <> abbr <> " " <> zone

  defdelegate time_to_string(hour, minute, second, microsecond), to: Calendar.ISO

  def day_rollover_relative_to_midnight_utc(), do: {0, 1}

  def naive_datetime_from_iso_days(entry) do
    {year, month, day, hour, minute, second, microsecond} =
      Calendar.ISO.naive_datetime_from_iso_days(entry)

    {year + 10_000, month, day, hour, minute, second, microsecond}
  end

  def naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond) do
    Calendar.ISO.naive_datetime_to_iso_days(
      year - 10_000,
      month,
      day,
      hour,
      minute,
      second,
      microsecond
    )
  end

  defp zero_pad(val, count) when val >= 0 do
    String.pad_leading("#{val}", count, ["0"])
  end

  defp zero_pad(val, count) do
    "-" <> zero_pad(-val, count)
  end

  def parse_date(string) do
    {year, month, day} =
      string
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    if valid_date?(year, month, day) do
      {:ok, {year, month, day}}
    else
      {:error, :invalid_date}
    end
  end

  def valid_date?(year, month, day) do
    :calendar.valid_date(year, month, day)
  end

  def months_in_year(year) do
    Calendar.ISO.months_in_year(year - 10_000)
  end

  def days_in_month(year, month) do
    Calendar.ISO.days_in_month(year - 10_000, month)
  end

  def leap_year?(year) do
    Calendar.ISO.leap_year?(year - 10_000)
  end

  def day_of_week(year, month, day, starting_on) do
    Calendar.ISO.day_of_week(year - 10_000, month, day, starting_on)
  end

  def day_of_year(year, month, day) do
    Calendar.ISO.day_of_year(year - 10_000, month, day)
  end

  def quarter_of_year(year, month, day) do
    Calendar.ISO.quarter_of_year(year - 10_000, month, day)
  end

  def year_of_era(year) do
    Calendar.ISO.year_of_era(year - 10_000)
  end

  if {:year_of_era, 3} in Calendar.ISO.__info__(:functions) do
    def year_of_era(year, month, day) do
      Calendar.ISO.year_of_era(year - 10_000, month, day)
    end
  end

  def day_of_era(year, month, day) do
    Calendar.ISO.day_of_era(year - 10_000, month, day)
  end

  defdelegate parse_time(string), to: Calendar.ISO

  defdelegate parse_naive_datetime(string), to: Calendar.ISO

  defdelegate parse_utc_datetime(string), to: Calendar.ISO

  defdelegate time_from_day_fraction(day_fraction), to: Calendar.ISO

  defdelegate time_to_day_fraction(hour, minute, second, microsecond), to: Calendar.ISO

  defdelegate valid_time?(hour, minute, second, microsecond), to: Calendar.ISO

  if {:iso_days_to_end_of_day, 1} in Calendar.ISO.__info__(:functions) do
    defdelegate iso_days_to_beginning_of_day(iso_days), to: Calendar.ISO

    defdelegate iso_days_to_end_of_day(iso_days), to: Calendar.ISO
  end
end
