defmodule Tox.Time do
  @moduledoc """
  A set of functions to work with `Time`.
  """

  alias Tox.IsoDays

  @doc """
  Adds `durations` to the given `naive_datetime`.

  The `durations` is a keyword list of one or more durations of the type
  `Tox.duration` e.g. `[hour: 1, minute: 5, second: 500]`.

  ## Examples

      iex> time = ~T[12:00:00]
      iex> Tox.Time.shift(time, hour: 2)
      ~T[14:00:00.000000]
      iex> Tox.Time.shift(time, hour: -2, minute: 10, second: 48)
      ~T[10:10:48.000000]
      iex> Tox.Time.shift(time, day: 2)
      ~T[12:00:00.000000]
      iex> Tox.Time.shift(time, minute: 90)
      ~T[13:30:00.000000]
      iex> Tox.Time.shift(time, minute: -90)
      ~T[10:30:00.000000]
      iex> Tox.Time.shift(time, minute: -59, hour: -23)
      ~T[12:01:00.000000]
      iex> Tox.Time.shift(time, minute: -24 * 60)
      ~T[12:00:00.000000]
      iex> Tox.Time.shift(time, second: 24 * 60 * 60)
      ~T[12:00:00.000000]

  """
  @spec shift(Calendar.time(), [Tox.duration()]) :: Time.t()
  def shift(
        %{
          calendar: calendar,
          hour: hour,
          minute: minute,
          second: second,
          microsecond: {_microsecond, precision} = microsecond
        },
        durations
      ) do
    {parts_in_day, parts_per_day} =
      calendar.time_to_day_fraction(hour, minute, second, microsecond)

    {_days, {parts, _fraction}} = IsoDays.from_durations_time(durations, calendar, precision)

    from_day_fraction({parts_in_day + parts, parts_per_day}, calendar)
  end

  @doc """
  Returns true if `time1` occurs after `time2`.

  ## Examples

      iex> Tox.Time.after?(~T[10:00:00], ~T[10:00:00.1])
      false

      iex> Tox.Time.after?(~T[12:00:00], ~T[11:59:59])
      true

      iex> Tox.Time.after?(~T[12:00:00], ~T[12:00:00])
      false

      iex> Tox.Time.after?(
      ...>   Time.convert!(~T[23:23:23], Calendar.Holocene),
      ...>   Time.convert!(~T[01:59:59], Calendar.Holocene)
      ...> )
      true

  """
  def after?(time1, time2) do
    Time.compare(time1, time2) == :gt
  end

  @doc """
  Returns true if `time1` occurs after `time2` or both dates are equal.

  ## Examples

      iex> Tox.Time.after_or_equal?(~T[10:00:00], ~T[10:00:00.1])
      false

      iex> Tox.Time.after_or_equal?(~T[12:00:00], ~T[11:59:59])
      true

      iex> Tox.Time.after_or_equal?(~T[12:00:00], ~T[12:00:00])
      true

      iex> Tox.Time.after_or_equal?(
      ...>   Time.convert!(~T[23:23:23], Calendar.Holocene),
      ...>   Time.convert!(~T[01:59:59], Calendar.Holocene)
      ...> )
      true

  """
  def after_or_equal?(time1, time2) do
    Time.compare(time1, time2) in [:gt, :eq]
  end

  @doc """
  Returns true if both times are equal.

  ## Examples

      iex> Tox.Time.equal?(~T[11:11:11], ~T[22:22:22])
      false

      iex> Tox.Time.equal?(~T[12:12:12], ~T[12:12:12])
      true

  """
  def equal?(time1, time2) do
    Time.compare(time1, time2) == :eq
  end

  @doc """
  Returns true if `time1` occurs before `time2`.

  ## Examples

      iex> Tox.Time.before?(~T[10:00:00], ~T[10:00:00.1])
      true

      iex> Tox.Time.before?(~T[12:00:00], ~T[11:59:59])
      false

      iex> Tox.Time.before?(~T[12:00:00], ~T[12:00:00])
      false

      iex> Tox.Time.before?(
      ...>   Time.convert!(~T[23:23:23], Calendar.Holocene),
      ...>   Time.convert!(~T[01:59:59], Calendar.Holocene)
      ...> )
      false

  """
  def before?(time1, time2) do
    Time.compare(time1, time2) == :lt
  end

  @doc """
  Returns true if `time1` occurs before `time2` or both dates are equal.

  ## Examples

      iex> Tox.Time.before_or_equal?(~T[10:00:00], ~T[10:00:00.1])
      true

      iex> Tox.Time.before_or_equal?(~T[12:00:00], ~T[11:59:59])
      false

      iex> Tox.Time.before_or_equal?(~T[12:00:00], ~T[12:00:00])
      true

      iex> Tox.Time.before_or_equal?(
      ...>   Time.convert!(~T[23:23:23], Calendar.Holocene),
      ...>   Time.convert!(~T[01:59:59], Calendar.Holocene)
      ...> )
      false

  """
  def before_or_equal?(time1, time2) do
    Time.compare(time1, time2) in [:lt, :eq]
  end

  @doc """
  Returns a boolean indicating whether `date` occurs between `from` and `to`.
  The optional `boundaries` specifies whether `from` and `to` are included or
  not. The possible value for `boundaries` are:

  * `:open`: `from` and `to` are excluded
  * `:closed`: `from` and `to` are included
  * `:left_open`: `from` is excluded and `to` is included
  * `:right_open`: `from` is included and `to` is excluded

  ## Examples

      iex> from = ~T[10:00:00]
      iex> to   = ~T[14:00:00]
      iex> Tox.Time.between?(~T[09:00:00], from, to)
      false
      iex> Tox.Time.between?(~T[12:00:00], from, to)
      true
      iex> Tox.Time.between?(~T[23:00:00], from, to)
      false
      iex> Tox.Time.between?(~T[10:00:00], from, to)
      true
      iex> Tox.Time.between?(~T[14:00:00], from, to)
      false
      iex> Tox.Time.between?(~T[10:00:00], from, to, :open)
      false
      iex> Tox.Time.between?(~T[14:00:00], from, to, :open)
      false
      iex> Tox.Time.between?(~T[10:00:00], from, to, :closed)
      true
      iex> Tox.Time.between?(~T[14:00:00], from, to, :closed)
      true
      iex> Tox.Time.between?(~T[10:00:00], from, to, :left_open)
      false
      iex> Tox.Time.between?(~T[14:00:00], from, to, :left_open)
      true
      iex> Tox.Time.between?(~T[00:00:00], to, from)
      ** (ArgumentError) from is equal or greater as to

  """
  @spec between?(Calendar.time(), Calendar.time(), Calendar.time(), Tox.boundaries()) ::
          boolean()
  def between?(time, from, to, boundaries \\ :right_open)
      when boundaries in [:closed, :left_open, :right_open, :open] do
    if Time.compare(from, to) in [:gt, :eq],
      do: raise(ArgumentError, "from is equal or greater as to")

    case {Time.compare(time, from), Time.compare(time, to), boundaries} do
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
  Return the minimal time.

  ## Examples

      iex> Tox.Time.min()
      ~T[00:00:00]

      iex> Tox.Time.min(Calendar.Holocene)
      %Time{
        hour: 0,
        minute: 0,
        second: 0,
        microsecond: {0, 0},
        calendar: Calendar.Holocene
      }

  """
  @spec min(Calendar.calendar()) :: Time.t()
  def min(calendar \\ Calendar.ISO) do
    {:ok, time} = Time.new(0, 0, 0, {0, 0}, calendar)
    time
  end

  @doc """
  Return the maximum time.

  ## Example

      iex> Tox.Time.max()
      ~T[23:59:59.999999]

      iex> Tox.Time.max(Calendar.Holocene)
      %Time{
        hour: 23,
        minute: 59,
        second: 59,
        microsecond: {999999, 6},
        calendar: Calendar.Holocene
      }

  """
  @spec max(Calendar.calendar()) :: Time.t()
  def max(calendar \\ Calendar.ISO) do
    {hour, minute, second, microsecond} = max_tuple(calendar)
    {:ok, time} = Time.new(hour, minute, second, microsecond, calendar)
    time
  end

  @doc false
  @spec max_tuple(Calendar.calendar()) ::
          {Calendar.hour(), Calendar.minute(), Calendar.second(), Calendar.microsecond()}
  def max_tuple(calendar) do
    {_parts, parts_per_day} = calendar.time_to_day_fraction(0, 0, 0, {0, 0})
    calendar.time_from_day_fraction({parts_per_day - 1, parts_per_day})
  end

  # Helper

  defp from_day_fraction({parts_in_day, parts_per_day}, calendar) do
    remainder = rem(parts_in_day, parts_per_day)

    new_parts_in_day =
      case remainder < 0 do
        true -> parts_per_day + remainder
        false -> remainder
      end

    {hour, minute, second, microsecond} =
      calendar.time_from_day_fraction({new_parts_in_day, parts_per_day})

    {:ok, time} = Time.new(hour, minute, second, microsecond, calendar)
    time
  end
end
