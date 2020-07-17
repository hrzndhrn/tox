defmodule Tox.Period do
  @moduledoc """
  A `Period` struct and functions.

  The `Period` struct contains the fields `year`, `month`, `week`, `day`,
  `hour`, `minute` and `second`. The values for the fields are representing the
  amount of time for an unit. Expected `second`, all values are integers equals
  or greater `0`. The filed `second` can also be a float equals or greate `0`.
  """

  @microseconds_per_second 1_000_000

  @key_map_date %{?Y => :year, ?M => :month, ?W => :week, ?D => :day}
  @key_map_time %{?H => :hour, ?M => :minute, ?S => :second}

  @typedoc """
  An amount of time with a specified unit e.g. `{second: 5.500}` or `{hour: 1}`.
  The amount of all durations must be equal or greater as 0.
  """
  @type duration ::
          {:year, non_neg_integer()}
          | {:month, non_neg_integer}
          | {:week, non_neg_integer}
          | {:day, non_neg_integer}
          | {:hour, non_neg_integer}
          | {:minute, non_neg_integer}
          | {:second, non_neg_integer}

  @type t :: %__MODULE__{
          year: non_neg_integer(),
          month: non_neg_integer(),
          week: non_neg_integer(),
          day: non_neg_integer(),
          hour: non_neg_integer(),
          minute: non_neg_integer(),
          second: non_neg_integer() | float()
        }

  defstruct year: 0, month: 0, week: 0, day: 0, hour: 0, minute: 0, second: 0

  @doc """
  Creates a new period. All values in durations must be greater or equal `0`.

  ## Examples

      iex> {:ok, period} = Tox.Period.new(1, 2, 3, 4, 5, 6, 7.8)
      iex> period
      #Tox.Period<P1Y2M3W4DT5H6M7.8S>

      iex> Tox.Period.new(1, 2, 3, 4, 5, 6, -7.8)
      {:error, :invalid_period}

  """
  @spec new(
          year :: non_neg_integer(),
          month :: non_neg_integer(),
          week :: non_neg_integer(),
          day :: non_neg_integer(),
          hour :: non_neg_integer(),
          minute :: non_neg_integer(),
          second :: non_neg_integer() | float
        ) :: {:ok, t()} | {:error, :invalid_period}
  def new(year, month, week, day, hour, minute, second) do
    new(
      year: year,
      month: month,
      week: week,
      day: day,
      hour: hour,
      minute: minute,
      second: second
    )
  end

  @doc """
  Creates a new period or raise an error.

  See `new/7` for more informations.

  ## Examples

      iex> Tox.Period.new!(1, 2, 3, 4, 5, 6, 7.8)
      #Tox.Period<P1Y2M3W4DT5H6M7.8S>

      iex> Tox.Period.new!(1, 2, 3, 4, 5, 6, -7.8)
      ** (ArgumentError) cannot create a new period with [year: 1, month: 2, week: 3, day: 4, hour: 5, minute: 6, second: -7.8], reason: :invalid_period

  """
  @spec new!(
          year :: non_neg_integer(),
          month :: non_neg_integer(),
          week :: non_neg_integer(),
          day :: non_neg_integer(),
          hour :: non_neg_integer(),
          minute :: non_neg_integer(),
          second :: non_neg_integer() | float
        ) :: t()
  def new!(year, month, week, day, hour, minute, second) do
    new!(
      year: year,
      month: month,
      week: week,
      day: day,
      hour: hour,
      minute: minute,
      second: second
    )
  end

  @doc """
  Creates a new period from `durations`. All values in the `durations` must be
  equal or greater `0`.

  ## Examples

      iex> {:ok, period} = Tox.Period.new(day: 4, hour: 5)
      iex> period
      #Tox.Period<P4DT5H>

      iex> Tox.Period.new(minute: -1)
      {:error, :invalid_period}

  """
  @spec new([duration()]) :: {:ok, t()} | {:error, :invalid_period}
  def new(durations) do
    case is_valid?(durations) do
      true -> {:ok, struct(__MODULE__, durations)}
      false -> {:error, :invalid_period}
    end
  end

  @doc """
  Creates a new period from `durations` or raises an error.

  See `new/1` for more informations.

  ## Examples

      iex> Tox.Period.new!(month: 1, minute: 1)
      #Tox.Period<P1MT1M>

      iex> Tox.Period.new!(year: 0.5)
      ** (ArgumentError) cannot create a new period with [year: 0.5], reason: :invalid_period

  """
  @spec new!([duration()]) :: t()
  def new!(durations) do
    case new(durations) do
      {:ok, period} ->
        period

      {:error, reason} ->
        raise ArgumentError,
              "cannot create a new period with #{inspect(durations)}, " <>
                "reason: #{inspect(reason)}"
    end
  end

  @doc """
  Creates a new period from a string.

  A string representation of a period has the format `PiYiMiWiDTiHiMfS`. The `i`
  represents an integer and the `f` a float. All integers and the float must be
  equal or greater as `0`. Leading zeros are not required.  The capital letters
  `P` , `Y`, `M`, `W`, `D`, `T`, `H`, `M`, and `S` are designators for each of
  the date and time elements and are not replaced.

  * P is the period designator (optional).
    * Y is the year designator that follows the value for the number of years.
    * M is the month designator that follows the value for the number of months.
    * W is the week designator that follows the value for the number of weeks.
    * D is the day designator that follows the value for the number of days.
  * T is the time designator that precedes the time components of the representation.
    * H is the hour designator that follows the value for the number of hours.
    * M is the minute designator that follows the value for the number of minutes.
    * S is the second designator that follows the value for the number of seconds.

  ## Examples

      iex> Tox.Period.parse("1Y3M")
      Tox.Period.new(year: 1, month: 3)

      iex> Tox.Period.parse("T12M5.5S")
      Tox.Period.new(minute: 12, second: 5.5)

      iex> Tox.Period.parse("P1Y3MT2H")
      Tox.Period.new(year: 1, month: 3, hour: 2)

      iex> Tox.Period.parse("1y")
      {:error, :invalid_format}

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, :invalid_format}
  def parse("P" <> string) when is_binary(string), do: parse(string)

  def parse(string) when is_binary(string) do
    with {:ok, durations} <- do_parse(string) do
      new(durations)
    end
  end

  @doc """
  Creates a new period from a string.

  See `parse/1` for more informations.

  ## Examples

      iex> Tox.Period.parse!("T12M5.5S")
      #Tox.Period<PT12M5.5S>

      iex> Tox.Period.parse!("1y")
      ** (ArgumentError) cannot parse "1y" as period, reason: :invalid_format

  """
  @spec parse!(String.t()) :: t()
  def parse!(string) do
    case parse(string) do
      {:ok, period} ->
        period

      {:error, reason} ->
        raise ArgumentError,
              "cannot parse #{inspect(string)} as period, reason: #{inspect(reason)}"
    end
  end

  @doc """
  Returns the `period` as `[Tox.duration]`. The optional `sign` can be `:pos`
  for positive `durations` and `:neg` for negative `durations`, defaults to
  `:pos`. A duration with an amount of `0` will be excluded form the
  `durations`.

  ## Examples

      iex> {:ok, period} = Tox.Period.parse("P1Y3MT2H1.123S")
      iex> Tox.Period.to_durations(period)
      [year: 1, month: 3, hour: 2, second: 1, microsecond: 123000]
      iex> Tox.Period.to_durations(period, :neg)
      [year: -1, month: -3, hour: -2, second: -1, microsecond: -123000]

      iex> {:ok, period} = Tox.Period.parse("1MT1M")
      iex> Tox.Period.to_durations(period)
      [month: 1, minute: 1]

  """
  @spec to_durations(t(), :pos | :neg) :: [Tox.duration()]
  def to_durations(period, sign \\ :pos)

  def to_durations(%__MODULE__{} = period, sign) when sign in [:pos, :neg] do
    Enum.reduce([:second, :minute, :hour, :day, :week, :month, :year], [], fn key, durations ->
      do_to_durations(durations, period, key, sign)
    end)
  end

  # Helpers

  defp is_valid?(durations) do
    Enum.any?(durations, fn {_unit, value} -> value > 0 end) &&
      Enum.all?(durations, fn
        {:second, value} -> is_number(value) && value >= 0
        {_unit, value} -> is_integer(value) && value >= 0
      end)
  end

  defp do_to_durations(durations, %__MODULE__{} = period, :second, sign) do
    value = Map.fetch!(period, :second)
    second = trunc(value)
    microsecond = trunc((value - second) * @microseconds_per_second)

    durations
    |> do_to_durations(microsecond, :microsecond, sign)
    |> do_to_durations(second, :second, sign)
  end

  defp do_to_durations(durations, %__MODULE__{} = period, key, sign) do
    case {Map.fetch!(period, key), sign} do
      {value, :pos} when value > 0 -> Keyword.put(durations, key, value)
      {value, :neg} when value > 0 -> Keyword.put(durations, key, value * -1)
      _zero -> durations
    end
  end

  defp do_to_durations(durations, 0, _key, _sign), do: durations

  defp do_to_durations(durations, value, key, sign) when is_integer(value) do
    value =
      case sign do
        :pos -> value
        :neg -> value * -1
      end

    Keyword.put(durations, key, value)
  end

  defp do_parse(string) when is_binary(string) do
    string
    |> String.split("T")
    |> case do
      [date] ->
        do_parse(date, @key_map_date)

      ["", time] ->
        do_parse(time, @key_map_time)

      [date, time] ->
        with {:ok, durations_date} <- do_parse(date, @key_map_date),
             {:ok, durations_time} <- do_parse(time, @key_map_time) do
          {:ok, Keyword.merge(durations_date, durations_time)}
        end
    end
  end

  defp do_parse(string, key_map) when is_binary(string) do
    designators_list = Map.keys(key_map)

    string
    |> String.to_charlist()
    |> Enum.reduce_while({[], []}, fn char, {designators, num} ->
      cond do
        char == ?. ->
          {:cont, {designators, [char | num]}}

        char in ?0..?9 ->
          {:cont, {designators, [char | num]}}

        char in designators_list ->
          with {:ok, key} <- Map.fetch(key_map, char),
               {:ok, value} <- parse_value(key, Enum.reverse(num)) do
            {:cont, {Keyword.put(designators, key, value), []}}
          else
            :error -> {:halt, :error}
          end

        true ->
          {:halt, :error}
      end
    end)
    |> case do
      {durations, []} -> {:ok, durations}
      _error -> {:error, :invalid_format}
    end
  end

  defp parse_value(:second, num) do
    num
    |> to_string()
    |> Float.parse()
    |> case do
      {value, ""} -> {:ok, value}
      _error -> :error
    end
  end

  defp parse_value(_key, num) do
    num
    |> to_string()
    |> Integer.parse()
    |> case do
      {value, ""} -> {:ok, value}
      _error -> :error
    end
  end

  defimpl Inspect do
    alias Tox.Period

    @spec inspect(Period.t(), Keyword.t()) :: String.t()
    def inspect(period, _opts) do
      "#Tox.Period<#{to_string(period)}>"
    end
  end

  defimpl String.Chars do
    alias Tox.Period

    @designators %{
      year: 'Y',
      month: 'M',
      week: 'W',
      day: 'D',
      hour: 'H',
      minute: 'M',
      second: 'S'
    }

    @spec to_string(Period.t()) :: String.t()
    def to_string(period) do
      period_date = period_to_string(period, [:year, :month, :week, :day])
      period_time = period_to_string(period, [:hour, :minute, :second])

      if period_time == "", do: "P#{period_date}", else: "P#{period_date}T#{period_time}"
    end

    defp period_to_string(period, keys) do
      Enum.reduce(keys, "", fn key, string ->
        case Map.fetch!(period, key) do
          value when value > 0 -> "#{string}#{value}#{Map.fetch!(@designators, key)}"
          _zero -> string
        end
      end)
    end
  end
end

defmodule Tox.Period.Sigil do
  @moduledoc """
  A `~P` sigil for periods.
  """
  alias Tox.Period

  @doc """
  Handles the sigil `~P` for periods.

  ## Examples

      iex> import Tox.Period.Sigil
      iex> ~P[1Y2DT1H10.10S]
      #Tox.Period<P1Y2DT1H10.1S>
      iex> ~P[1y]
      ** (ArgumentError) cannot parse "1y" as period

  """
  @spec sigil_P(binary(), list()) :: Period.t()
  def sigil_P(string, _modifiers) do
    case Period.parse(string) do
      {:ok, period} -> period
      {:error, _} -> raise ArgumentError, "cannot parse #{inspect(string)} as period"
    end
  end
end
