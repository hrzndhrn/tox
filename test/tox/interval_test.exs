defmodule Tox.IntervalTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Tox.Interval

  @seconds_per_minute 60
  @seconds_per_hour 60 * @seconds_per_minute

  describe "new!3" do
    test "raises error for invalid interval" do
      message =
        "cannot create a new interval with #Tox.Period<P1M>, " <>
          "#Tox.Period<P1M>, and :right_open reason: :invalid_interval"

      assert_raise ArgumentError, message, fn ->
        Tox.Interval.new!(
          Tox.Period.new!(month: 1),
          Tox.Period.new!(month: 1)
        )
      end
    end

    test "raises error for invalid interval with two datetimes" do
      message = ~r/cannot create.*reason: :invalid_interval/

      assert_raise ArgumentError, message, fn ->
        Tox.Interval.new!(
          DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Etc/UTC"),
          DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Etc/UTC")
        )
      end
    end
  end

  describe "since_start/3" do
    test "returns seconds since start" do
      now = DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Etc/UTC")

      interval =
        Tox.Interval.new!(
          Tox.DateTime.shift(now, hour: -1),
          Tox.Period.new!(hour: 2, minute: 10)
        )

      assert Tox.Interval.since_start(interval, now) == {:ok, @seconds_per_hour}
    end

    test "returns an error if interval does not contains datetime" do
      now = DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Etc/UTC")

      interval =
        Tox.Interval.new!(
          Tox.DateTime.shift(now, hour: -10),
          Tox.Period.new!(hour: 2)
        )

      assert Tox.Interval.since_start(interval, now) == :error
    end
  end

  describe "until_ending/3" do
    test "returns seconds until ending" do
      now = DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Etc/UTC")

      interval =
        Tox.Interval.new!(
          Tox.DateTime.shift(now, hour: -1),
          Tox.Period.new!(hour: 2, minute: 10)
        )

      assert Tox.Interval.until_ending(interval, now) ==
               {:ok, @seconds_per_hour + 10 * @seconds_per_minute}
    end

    test "returns an error if interval does not contain datetime" do
      now = DateTime.from_naive!(~N[2020-07-11 08:06:00.123456], "Europe/Berlin")

      interval =
        Tox.Interval.new!(
          Tox.DateTime.shift(now, hour: -10),
          Tox.Period.new!(hour: 2)
        )

      assert Tox.Interval.until_ending(interval, now) == :error
    end
  end

  @tag :only
  property "interval datetime/period" do
    check all datetime <- Generator.datetime(),
              period <- Generator.period() do
      assert {:ok, interval} = Tox.Interval.new(datetime, period)
      assert %DateTime{} = ending = Tox.Interval.ending_datetime(interval)
      assert_contains(interval, datetime, ending)
      assert_boundaries(interval, datetime, ending)
    end
  end

  defp assert_contains(interval, start, ending) do
    refute Tox.Interval.contains?(interval, DateTime.add(start, -1))
    refute Tox.Interval.contains?(interval, DateTime.add(ending, 1))

    inside =
      DateTime.add(ending, div(DateTime.diff(start, ending, :microsecond), 2), :microsecond)

    assert Tox.Interval.contains?(interval, inside)
  end

  defp assert_boundaries(%Tox.Interval{boundaries: :closed} = interval, start, ending) do
    assert Tox.Interval.contains?(interval, start)
    assert Tox.Interval.contains?(interval, ending)
  end

  defp assert_boundaries(%Tox.Interval{boundaries: :open} = interval, start, ending) do
    refute Tox.Interval.contains?(interval, start)
    refute Tox.Interval.contains?(interval, ending)
  end

  defp assert_boundaries(%Tox.Interval{boundaries: :right_open} = interval, start, ending) do
    assert Tox.Interval.contains?(interval, start)
    refute Tox.Interval.contains?(interval, ending)
  end

  defp assert_boundaries(%Tox.Interval{boundaries: :left_open} = interval, start, ending) do
    refute Tox.Interval.contains?(interval, start)
    assert Tox.Interval.contains?(interval, ending)
  end
end
