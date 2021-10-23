defmodule Generator do
  @moduledoc false

  @units [:year, :month, :week, :day, :hour, :minute, :second, :millisecond, :microsecond]
  @calendars [
    Calendar.ISO,
    Cldr.Calendar.Coptic
    # Use Cldr.Calendar.Ethiopic again when a new version of the package is released.
    # Cldr.Calendar.Ethiopic
  ]

  def naive_datetime, do: StreamData.map(naive_datetime_iso(), &convert/1)

  def naive_datetime_iso do
    from = ~N[1990-01-01 00:00:00.000000]
    to = ~N[2100-01-01 23:59:59.999999]
    diff = NaiveDateTime.diff(to, from, :microsecond)

    0..diff
    |> StreamData.integer()
    |> StreamData.map(fn microseconds ->
      NaiveDateTime.add(from, microseconds, :microsecond)
    end)
  end

  def datetime, do: StreamData.map(naive_datetime(), &to_datetime/1)

  def date, do: StreamData.map(date_iso(), &convert/1)

  def date_iso do
    from = ~D[1990-01-01]
    to = ~D[2100-01-01]
    diff = Date.diff(to, from)

    0..diff
    |> StreamData.integer()
    |> StreamData.map(fn days ->
      Date.add(from, days)
    end)
  end

  def time, do: StreamData.map(time_iso(), &convert/1)

  def time_iso do
    from = ~T[00:00:00]
    to = ~T[23:59:59.999999]
    diff = Time.diff(to, from, :microsecond)

    0..diff
    |> StreamData.integer()
    |> StreamData.map(fn microseconds ->
      Time.add(from, microseconds, :microsecond)
    end)
  end

  def period, do: StreamData.map(durations(), &to_period/1)

  def durations do
    0..length(@units)
    |> StreamData.integer()
    |> StreamData.map(&durations/1)
  end

  defp durations(count) do
    durations(count, @units, [])
  end

  defp durations(0, _units, durations), do: durations

  defp durations(count, units, durations) do
    {unit, units} = pop(units)
    duration = {unit, :rand.uniform(400) - 200}
    durations(count - 1, units, [duration | durations])
  end

  defp pop(list), do: List.pop_at(list, :rand.uniform(length(list)) - 1)

  defp to_datetime(naive_datetime) do
    case DateTime.from_naive(naive_datetime, Enum.random(TimeZoneInfo.time_zones())) do
      {:ok, datetime} -> datetime
      {:gap, datetime1, datetime2} -> Enum.random([datetime1, datetime2])
      {:ambiguous, datetime1, datetime2} -> Enum.random([datetime1, datetime2])
    end
  end

  defp convert(%module{} = value) do
    module.convert!(value, Enum.random(@calendars))
  end

  defp to_period([]), do: Tox.Period.new!(day: 1)

  defp to_period(durations) do
    durations =
      durations
      |> Enum.filter(fn {unit, _amoung} -> unit not in [:millisecond, :week, :microsecond] end)
      |> Enum.map(fn {unit, amount} -> {unit, abs(amount)} end)

    sum = Enum.reduce(durations, 0, fn {_unit, amount}, acc -> amount + acc end)

    case sum == 0 do
      true -> Tox.Period.new!(hour: 1)
      false -> Tox.Period.new!(durations)
    end
  end
end
