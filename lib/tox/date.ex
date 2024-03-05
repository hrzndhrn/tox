defmodule Tox.Date do
  @moduledoc """
  A set of functions to work with `Date`.
  """

  @doc """
  Shifts the `date` by the given `duration`.


  The `durations` is a keyword list of one or more durations of the type
  `Tox.duration` e.g. `[year: 1, month: 5, day: 500]`. All values will be
  shifted from the largest to the smallest unit.

  ## Examples

      iex> date = ~D[1980-11-01]
      iex> Tox.Date.shift(date, year: 2)
      ~D[1982-11-01]
      iex> Tox.Date.shift(date, year: -2, month: 1, day: 40)
      ~D[1979-01-10]
      # time units will be ignored
      iex> Tox.Date.shift(date, hour: 100, minute: 10, second: 10)
      ~D[1980-11-01]

  Adding a month at the end of the month can update the day too.

      iex> Tox.Date.shift(~D[2000-01-31], month: 1)
      ~D[2000-02-29]

  For that reason it is important to know that all values will be shifted from the
  largest to the smallest unit.

      iex> date = ~D[2000-01-30]
      iex> Tox.Date.shift(date, month: 1, day: 1)
      ~D[2000-03-01]
      iex> date |> Tox.Date.shift(month: 1) |> Tox.Date.shift(day: 1)
      ~D[2000-03-01]
      iex> date |> Tox.Date.shift(day: 1) |> Tox.Date.shift(month: 1)
      ~D[2000-02-29]

  Using `shift/2` with a different calendar.

      iex> ~D[2000-12-30]
      ...> |> Date.convert!(Cldr.Calendar.Coptic)
      ...> |> Tox.Date.shift(day: 3)
      %Date{year: 1717, month: 4, day: 24, calendar: Cldr.Calendar.Coptic}

  """
  @spec shift(Calendar.date(), [Tox.duration()]) :: Date.t()
  def shift(date, durations) do
    date
    |> shift_years(Keyword.get(durations, :year, 0))
    |> shift_months(Keyword.get(durations, :month, 0))
    |> Date.add(
      Keyword.get(durations, :day, 0) + Keyword.get(durations, :week, 0) * Tox.days_per_week()
    )
  end

  @doc """
  Returns an `{year, week}` representing the ISO week number for the specified
  date.

  This function is just defined for dates with `Calendar.ISO`.

  ## Example

      iex> Tox.Date.week(~D[2017-01-01])
      {2016, 52}
      iex> Tox.Date.week(~D[2020-01-01])
      {2020, 1}
      iex> Tox.Date.week(~D[2019-12-31])
      {2020, 1}
      iex> ~D[2020-06-04]
      ...> |> Date.convert(Cldr.Calendar.Ethiopic)
      ...> |> Tox.Date.week()
      ** (FunctionClauseError) no function clause matching in Tox.Date.week/1

  """
  @spec week(Calendar.date()) :: {Calendar.year(), non_neg_integer}
  def week(%{calendar: Calendar.ISO} = date), do: Tox.week(date)

  @doc """
  Returns true if `date1` occurs after `date2`.

  ## Examples

      iex> Tox.Date.after?(~D[2020-06-14], ~D[2020-06-22])
      false

      iex> Tox.Date.after?(~D[2020-07-14], ~D[2020-06-22])
      true

      iex> Tox.Date.after?(~D[2020-01-01], ~D[2020-01-01])
      false

      iex> Tox.Date.after?(
      ...>   Date.convert!(~D[2000-01-22], Cldr.Calendar.Coptic),
      ...>   Date.convert!(~D[2000-01-01], Cldr.Calendar.Coptic)
      ...> )
      true

  """
  defmacro after?(date1, date2) do
    quote do
      Date.compare(unquote(date1), unquote(date2)) == :gt
    end
  end

  @doc """
  Returns true if `date1` occurs after `date2` or both dates are equal.

  ## Examples

      iex> Tox.Date.after_or_equal?(~D[2020-06-14], ~D[2020-06-22])
      false

      iex> Tox.Date.after_or_equal?(~D[2020-07-14], ~D[2020-06-22])
      true

      iex> Tox.Date.after_or_equal?(~D[2020-01-01], ~D[2020-01-01])
      true

      iex> Tox.Date.after_or_equal?(
      ...>   Date.convert!(~D[2000-01-22], Cldr.Calendar.Ethiopic),
      ...>   Date.convert!(~D[2000-01-01], Cldr.Calendar.Ethiopic)
      ...> )
      true

  """
  defmacro after_or_equal?(date1, date2) do
    quote do
      Date.compare(unquote(date1), unquote(date2)) in [:gt, :eq]
    end
  end

  @doc """
  Returns true if both datets are equal.

  ## Examples

      iex> Tox.Date.equal?(~D[2020-07-14], ~D[2020-06-22])
      false

      iex> Tox.Date.equal?(~D[2020-01-01], ~D[2020-01-01])
      true

      iex> ethiopic = Date.convert!(~D[2000-01-01], Cldr.Calendar.Ethiopic)
      %Date{year: 1992, month: 4, day: 22, calendar: Cldr.Calendar.Ethiopic}
      iex> coptic = Date.convert!(~D[2000-01-01], Cldr.Calendar.Coptic)
      %Date{year: 1716, month: 4, day: 22, calendar: Cldr.Calendar.Coptic}
      iex> Tox.Date.equal?(ethiopic, coptic)
      true

  """
  defmacro equal?(date1, date2) do
    quote do
      Date.compare(unquote(date1), unquote(date2)) == :eq
    end
  end

  @doc """
  Returns true if `date1` occurs before `date2`.

  ## Examples

      iex> Tox.Date.before?(~D[2020-06-14], ~D[2020-06-22])
      true

      iex> Tox.Date.before?(~D[2020-07-14], ~D[2020-06-22])
      false

      iex> Tox.Date.before?(~D[2020-01-01], ~D[2020-01-01])
      false

      iex> Tox.Date.before?(
      ...>   Date.convert!(~D[2000-01-22], Cldr.Calendar.Ethiopic),
      ...>   Date.convert!(~D[2000-06-01], Cldr.Calendar.Ethiopic)
      ...> )
      true

  """
  defmacro before?(date1, date2) do
    quote do
      Date.compare(unquote(date1), unquote(date2)) == :lt
    end
  end

  @doc """
  Returns true if `date1` occurs before `date2` or both dates are equal.

  ## Examples

      iex> Tox.Date.before_or_equal?(~D[2020-06-14], ~D[2020-06-22])
      true

      iex> Tox.Date.before_or_equal?(~D[2020-07-14], ~D[2020-06-22])
      false

      iex> Tox.Date.before_or_equal?(~D[2020-01-01], ~D[2020-01-01])
      true

      iex> Tox.Date.before_or_equal?(
      ...>   Date.convert!(~D[2000-01-22], Cldr.Calendar.Ethiopic),
      ...>   Date.convert!(~D[2000-06-01], Cldr.Calendar.Ethiopic)
      ...> )
      true

  """
  defmacro before_or_equal?(date1, date2) do
    quote do
      Date.compare(unquote(date1), unquote(date2)) in [:lt, :eq]
    end
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

      iex> from = ~D[2020-02-01]
      iex> to   = ~D[2020-03-01]
      iex> Tox.Date.between?(~D[2020-01-01], from, to)
      false
      iex> Tox.Date.between?(~D[2020-02-05], from, to)
      true
      iex> Tox.Date.between?(~D[2020-03-05], from, to)
      false
      iex> Tox.Date.between?(~D[2020-02-01], from, to)
      true
      iex> Tox.Date.between?(~D[2020-03-01], from, to)
      false
      iex> Tox.Date.between?(~D[2020-02-01], from, to, :open)
      false
      iex> Tox.Date.between?(~D[2020-03-01], from, to, :open)
      false
      iex> Tox.Date.between?(~D[2020-02-01], from, to, :closed)
      true
      iex> Tox.Date.between?(~D[2020-03-01], from, to, :closed)
      true
      iex> Tox.Date.between?(~D[2020-02-01], from, to, :left_open)
      false
      iex> Tox.Date.between?(~D[2020-03-01], from, to, :left_open)
      true
      iex> Tox.Date.between?(~D[2000-01-01], to, from)
      ** (ArgumentError) from is equal or greater as to

  """
  @spec between?(Calendar.date(), Calendar.date(), Calendar.date(), Tox.boundaries()) ::
          boolean()
  def between?(date, from, to, boundaries \\ :right_open)
      when boundaries in [:closed, :left_open, :right_open, :open] do
    if Date.compare(from, to) in [:gt, :eq],
      do: raise(ArgumentError, "from is equal or greater as to")

    case {Date.compare(date, from), Date.compare(date, to), boundaries} do
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
  Returns a date representing the start of the year.

  ## Examples

      iex> Tox.Date.beginning_of_year(~D[2020-11-11])
      ~D[2020-01-01]

  """
  @spec beginning_of_year(Calendar.date()) :: Calendar.date()
  def beginning_of_year(date), do: %{date | month: 1, day: 1}

  @doc """
  Returns a date representing the start of the month.

  ## Examples

      iex> Tox.Date.beginning_of_month(~D[2020-11-11])
      ~D[2020-11-01]

  """
  @spec beginning_of_month(Calendar.date()) :: Calendar.date()
  def beginning_of_month(date), do: %{date | day: 1}

  @doc """
  Returns a date representing the start of the week.

  ## Examples

      iex> Tox.Date.beginning_of_week(~D[2020-11-13])
      ~D[2020-11-09]

  """
  @deprecated "Use: Date.beginning_of_week/2 instead"
  @spec beginning_of_week(Calendar.date()) :: Calendar.date()
  def beginning_of_week(date), do: Date.beginning_of_week(date)

  @doc """
  Returns a date representing the end of the year.
  If the date cannot be determined, `{:error, reason}` is returned.

  ## Examples

      iex> Tox.Date.end_of_year(~D[2020-11-11])
      ~D[2020-12-31]

      iex> ~D[2020-11-11]
      iex> |> Date.convert!(Cldr.Calendar.Coptic)
      iex> |> Tox.Date.end_of_year()
      %Date{year: 1737, month: 13, day: 5, calendar: Cldr.Calendar.Coptic}

  """
  @spec end_of_year(Calendar.date()) :: Calendar.date()
  def end_of_year(%{calendar: calendar, year: year} = date) do
    month = calendar.months_in_year(year)
    day = calendar.days_in_month(year, month)
    %{date | month: month, day: day}
  end

  @doc """
  Returns a date representing the end of the month.

  ## Examples

      iex> Tox.Date.end_of_month(~D[2020-11-11])
      ~D[2020-11-30]

      iex> ~D[2020-12-31]
      ...> |> Date.convert!(Cldr.Calendar.Coptic)
      ...> |> Tox.Date.shift(day: 1)
      ...> |> Tox.Date.end_of_month()
      %Date{year: 1737, month: 4, day: 30, calendar: Cldr.Calendar.Coptic}

  """
  @spec end_of_month(Calendar.date()) :: Calendar.date()
  def end_of_month(%{calendar: calendar, year: year, month: month} = date) do
    day = calendar.days_in_month(year, month)
    %{date | day: day}
  end

  @doc """
  Returns a date representing the end of the week.

  ## Examples

      iex> Tox.Date.end_of_week(~D[2020-11-11])
      ~D[2020-11-15]

      iex> ~D[2020-11-11]
      ...> |> Date.convert!(Cldr.Calendar.Ethiopic)
      ...> |> Tox.Date.end_of_week()
      %Date{year: 2013, month: 3, day: 6, calendar: Cldr.Calendar.Ethiopic}

  """
  @spec end_of_week(Calendar.date()) :: Calendar.date()
  def end_of_week(%{calendar: calendar, year: year, month: month, day: day} = date) do
    day = Tox.days_per_week() - Tox.day_of_week(calendar, year, month, day)
    shift(date, day: day)
  end

  ## Helpers

  defp shift_years(date, 0), do: date

  defp shift_years(
         %{calendar: calendar, year: year, month: month, day: day} = date,
         years
       ) do
    updated_year = year + years
    updated_day = update_day(updated_year, month, day, calendar)

    %{date | year: updated_year, day: updated_day}
  end

  defp shift_months(date, 0), do: date

  defp shift_months(
         %{calendar: calendar, month: month, year: year, day: day} = date,
         months
       ) do
    {updated_year, updated_month} = shift_months(months, year, month, calendar)
    updated_day = update_day(updated_year, updated_month, day, calendar)

    %{date | year: updated_year, month: updated_month, day: updated_day}
  end

  defp shift_months(months, year, month, calendar) do
    months_per_year = calendar.months_in_year(year)

    updated_year = year + div(months, months_per_year)
    updated_month = month + rem(months, months_per_year)

    cond do
      updated_month <= 0 ->
        {updated_year - 1, months_per_year + updated_month}

      updated_month > months_per_year ->
        {updated_year + 1, updated_month - months_per_year}

      true ->
        {updated_year, updated_month}
    end
  end

  defp update_day(year, month, day, calendar), do: min(day, calendar.days_in_month(year, month))
end
