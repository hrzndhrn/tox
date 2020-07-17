defmodule Tox.TimeTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Tox.Time

  property "add/2" do
    check all time <- Generator.time(),
              durations <- Generator.durations() do
      assert valid_time?(Tox.Time.add(time, durations))
    end
  end

  defp valid_time?(%Time{
         calendar: calendar,
         hour: hour,
         minute: minute,
         second: second,
         microsecond: microsecond
       }) do
    calendar.valid_time?(hour, minute, second, microsecond)
  end

  defp valid_time?(_datetime), do: false
end
