defmodule Tox.Interval do
  @moduledoc """
  An `Interval` struct and functions.

  A time interval is the intervening time between two time points. The amount of
  intervening time is expressed by a by a combination of `DateTime`/`DateTime`,
  `Datetime`/`Period` or `Period`/`DateTime`.

  The key `boundaries` specifies if the `start` and `ending` belongs to the
  interval.

  Valid values for `boundaries` are:

  * `:open`: `start` and `ending` are excluded
  * `:closed`: `start` and `ending` are included
  * `:left_open`: `start` is excluded and `ending` is included
  * `:right_open`: (default) `start` is included and `ending` is excluded

  ## Examples

  The default `:right_open`:

      iex> datetime = DateTime.from_naive!(~N[2020-04-10 00:00:00], "America/Rainy_River")
      iex> {:ok, interval} = Tox.Interval.new(
      ...>   datetime, Tox.Period.new!(day: 1)
      ...> )
      iex> interval
      #Tox.Interval<[2020-04-10T00:00:00-05:00/P1D[>
      iex> Tox.Interval.contains?(interval, datetime)
      true
      iex> Tox.Interval.contains?(interval, Tox.DateTime.add(datetime, day: 1))
      false

  With `boundaries` set to `:open`:

      iex> datetime = DateTime.from_naive!(~N[2020-04-10 00:00:00], "America/Rainy_River")
      iex> {:ok, interval} = Tox.Interval.new(
      ...>   datetime, Tox.Period.new!(day: 1), :open
      ...> )
      iex> interval
      #Tox.Interval<]2020-04-10T00:00:00-05:00/P1D[>
      iex> Tox.Interval.contains?(interval, datetime)
      false
      iex> Tox.Interval.contains?(interval, Tox.DateTime.add(datetime, day: 1))
      false

  With `boundaries` set to `:left_open`:

      iex> datetime = DateTime.from_naive!(~N[2020-04-10 00:00:00], "America/Rainy_River")
      iex> {:ok, interval} = Tox.Interval.new(
      ...>   datetime, Tox.Period.new!(day: 1), :left_open
      ...> )
      iex> interval
      #Tox.Interval<]2020-04-10T00:00:00-05:00/P1D]>
      iex> Tox.Interval.contains?(interval, datetime)
      false
      iex> Tox.Interval.contains?(interval, Tox.DateTime.add(datetime, day: 1))
      true

  With `boundaries` set to `:closed`:

      iex> datetime = DateTime.from_naive!(~N[2020-04-10 00:00:00], "America/Rainy_River")
      iex> {:ok, interval} = Tox.Interval.new(
      ...>   datetime, Tox.Period.new!(day: 1), :closed
      ...> )
      iex> interval
      #Tox.Interval<[2020-04-10T00:00:00-05:00/P1D]>
      iex> Tox.Interval.contains?(interval, datetime)
      true
      iex> Tox.Interval.contains?(interval, Tox.DateTime.add(datetime, day: 1))
      true

  """

  alias Tox.Period

  @type boundary :: DateTime.t() | Period.t()

  @type t :: %__MODULE__{
          start: boundary(),
          ending: boundary(),
          boundaries: Tox.boundaries()
        }

  defstruct start: nil, ending: nil, boundaries: :right_open

  @doc """
  Creates a new interval.

  See [`module documentation`](#content) for more informations.

  ## Examples

      iex> {:ok, interval} = Tox.Interval.new(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      iex> interval
      #Tox.Interval<[2020-01-01T00:00:00+01:00/P1M[>

      iex> Tox.Interval.new(
      ...>   Tox.Period.new!(month: 1),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      {:error, :invalid_interval}

  """
  @spec new(boundary(), boundary(), Tox.boundaries()) :: {:ok, t()} | {:error, :invalid_interval}
  def new(start, ending, boundaries \\ :right_open) do
    case is_valid?(start, ending, boundaries) do
      true -> {:ok, struct(__MODULE__, start: start, ending: ending, boundaries: boundaries)}
      false -> {:error, :invalid_interval}
    end
  end

  @doc """
  Creates a new interval or raises an error.

  See [`module documentation`](#content) for more informations.

  ## Examples

      iex> Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      #Tox.Interval<[2020-01-01T00:00:00+01:00/P1M[>


  """
  @spec new!(boundary(), boundary(), Tox.boundaries()) :: t()
  def new!(start, ending, boundaries \\ :right_open) do
    case new(start, ending, boundaries) do
      {:ok, interval} ->
        interval

      {:error, reason} ->
        raise ArgumentError,
              "cannot create a new interval with #{inspect(start)}, " <>
                "#{inspect(ending)}, and #{inspect(boundaries)} " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns the datetime on which the interval ends.

  The interval boundaries are not influence the returned datetime.

  ## Examples

      iex> interval = Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      iex> Tox.Interval.ending_datetime(interval)
      #DateTime<2020-02-01 00:00:00+01:00 CET Europe/Berlin>

      iex> interval = Tox.Interval.new!(
      ...>   Tox.Period.new!(month: 1),
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin")
      ...> )
      iex> Tox.Interval.ending_datetime(interval)
      #DateTime<2020-01-01 00:00:00+01:00 CET Europe/Berlin>

  """
  @spec ending_datetime(t()) :: DateTime.t()
  def ending_datetime(%{start: start, ending: ending}), do: ending_datetime(start, ending)

  defp ending_datetime(_start, %DateTime{} = ending), do: ending

  defp ending_datetime(%DateTime{} = start, %Period{} = ending) do
    Tox.DateTime.add(start, Period.to_durations(ending))
  end

  @doc """
  Returns the datetime on which the interval starts.

  The interval boundaries are not influence the returned datetime.

  ## Examples

      iex> interval = Tox.Interval.new!(
      ...>   Tox.Period.new!(month: 1),
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin")
      ...> )
      iex> Tox.Interval.start_datetime(interval)
      #DateTime<2019-12-01 00:00:00+01:00 CET Europe/Berlin>

      iex> interval = Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      iex> Tox.Interval.start_datetime(interval)
      #DateTime<2020-01-01 00:00:00+01:00 CET Europe/Berlin>

  """
  @spec start_datetime(t()) :: DateTime.t()
  def start_datetime(%{start: start, ending: ending}), do: start_datetime(start, ending)

  defp start_datetime(%DateTime{} = start, _ending), do: start

  defp start_datetime(%Period{} = start, %DateTime{} = ending) do
    Tox.DateTime.add(ending, Period.to_durations(start, :neg))
  end

  @doc """
  Returns the next interval.

  The interval boundaries are not influence the returned datetime.

  ## Examples

      iex> interval = Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      iex> Tox.Interval.next(interval)
      #Tox.Interval<[2020-02-01T00:00:00+01:00/P1M[>

      iex> interval = Tox.Interval.new!(
      ...>   Tox.Period.new!(month: 1),
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin")
      ...> )
      iex> Tox.Interval.next(interval)
      #Tox.Interval<[P1M/2020-02-01T00:00:00+01:00[>

      iex> interval = Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin"),
      ...>   DateTime.from_naive!(~N[2020-01-02 00:00:00], "Europe/Berlin")
      ...> )
      iex> Tox.Interval.next(interval)
      #Tox.Interval<[2020-01-02T00:00:00+01:00/2020-01-03T00:00:00+01:00[>

  """
  @spec next(t()) :: t()
  def next(%{start: start, ending: ending, boundaries: boundaries}) do
    {new_start, new_ending} = next(start, ending)
    new!(new_start, new_ending, boundaries)
  end

  defp next(%DateTime{} = start, %Period{} = ending) do
    {Tox.DateTime.add(start, Period.to_durations(ending)), ending}
  end

  defp next(%Period{} = start, %DateTime{} = ending) do
    {start, Tox.DateTime.add(ending, Period.to_durations(start))}
  end

  defp next(%DateTime{} = start, %DateTime{} = ending) do
    diff = DateTime.diff(ending, start, :microsecond)
    {DateTime.add(start, diff, :microsecond), DateTime.add(ending, diff, :microsecond)}
  end

  @doc """
  Returns the previous interval.

  The interval boundaries are not influence the returned datetime.

  ## Examples

      iex> interval = Tox.Interval.new!(
      ...>   DateTime.from_naive!(~N[2020-02-01 00:00:00], "Europe/Berlin"),
      ...>   Tox.Period.new!(month: 1)
      ...> )
      iex> datetime = DateTime.from_naive!(~N[2020-01-01 00:00:00], "Europe/Berlin")
      iex> Tox.Interval.contains?(interval, datetime)
      false

  """
  @spec contains?(t(), DateTime.t()) :: boolean()
  def contains?(period, datetime) do
    Tox.DateTime.between?(
      datetime,
      start_datetime(period),
      ending_datetime(period),
      period.boundaries
    )
  end

  @doc """
  Returns `{:ok, amount}` where amount is the time since the start of the
  interval.

  If the interval does not contains the given `datetime` an `:error` will be
  returned.

  ## Examples

      iex> now = DateTime.utc_now()
      iex> interval =
      ...>   Tox.Interval.new!(
      ...>     Tox.DateTime.add(now, hour: -1),
      ...>     Tox.Period.new!(hour: 2, minute: 10)
      ...>   )
      iex> Tox.Interval.since_start(interval, now)
      {:ok, 3600}
      iex> Tox.Interval.since_start(interval, Tox.DateTime.add(now, hour: 10))
      :error

  """
  @spec since_start(t(), DateTime.t(), System.time_unit()) :: {:ok, integer()} | :error
  def since_start(period, datetime, unit \\ :second) do
    case contains?(period, datetime) do
      true -> {:ok, DateTime.diff(datetime, start_datetime(period), unit)}
      false -> :error
    end
  end

  @doc """
  Returns `{:ok, amount}` where amount is the time until the ending of the
  interval.

  If the interval does not contains the given `datetime` an `:error` will be
  returned.

  ## Examples

      iex> now = DateTime.utc_now()
      iex> interval =
      ...>   Tox.Interval.new!(
      ...>     Tox.DateTime.add(now, hour: -1),
      ...>     Tox.Period.new!(hour: 2, minute: 10)
      ...>   )
      iex> Tox.Interval.until_ending(interval, now)
      {:ok, 4200}
      iex> Tox.Interval.until_ending(interval, Tox.DateTime.add(now, hour: 10))
      :error

  """
  @spec until_ending(t(), DateTime.t(), System.time_unit()) :: {:ok, integer()} | :error
  def until_ending(period, datetime, unit \\ :second) do
    case contains?(period, datetime) do
      true -> {:ok, DateTime.diff(ending_datetime(period), datetime, unit)}
      false -> :error
    end
  end

  # Helpers

  defp is_valid?(%start_module{} = start, %ending_module{} = ending, boundaries)
       when boundaries in [:open, :closed, :left_open, :right_open] do
    case {start_module, ending_module} do
      {Period, Period} -> false
      {DateTime, DateTime} -> DateTime.diff(start, ending) < 0
      {DateTime, Period} -> true
      {Period, DateTime} -> true
    end
  end

  defp is_valid?(_start, _ending, _boundaries), do: false

  defimpl Inspect do
    @spec inspect(Tox.Interval.t(), Keyword.t()) :: String.t()
    def inspect(interval, _opts) do
      "#Tox.Interval<#{to_string(interval)}>"
    end
  end

  defimpl String.Chars do
    @spec to_string(Tox.Interval.t()) :: String.t()
    def to_string(%{start: start, ending: ending, boundaries: boundaries}) do
      string = "#{boundary_to_string(start)}/#{boundary_to_string(ending)}"

      case boundaries do
        :closed -> "[#{string}]"
        :open -> "]#{string}["
        :left_open -> "]#{string}]"
        :right_open -> "[#{string}["
      end
    end

    defp boundary_to_string(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

    defp boundary_to_string(%Period{} = period), do: String.Chars.to_string(period)
  end
end
