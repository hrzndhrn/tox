defmodule Tox.Calendar do
  @moduledoc false

  @days_per_week Tox.days_per_week()

  Code.ensure_loaded(Date)

  if function_exported?(Date, :beginning_of_week, 2) do
    @spec day_of_week(Date.t() | DateTime.t() | NaiveDateTime.t()) ::
            {
              day_of_week :: non_neg_integer(),
              first_day_of_week :: non_neg_integer(),
              last_day_of_week :: non_neg_integer()
            }
    def day_of_week(%{calendar: calendar, year: year, month: month, day: day}) do
      calendar.day_of_week(year, month, day, :default)
    end
  else
    @spec day_of_week(Date.t() | DateTime.t() | NaiveDateTime.t()) ::
            {
              day_of_week :: non_neg_integer(),
              first_day_of_week :: non_neg_integer(),
              last_day_of_week :: non_neg_integer()
            }
    def day_of_week(%{calendar: calendar, year: year, month: month, day: day}) do
      calendar.day_of_week(year, month, day)
    end
  end

  @spec beginning_of_week(Date.t() | DateTime.t() | NaiveDateTime.t()) :: non_neg_integer()
  def beginning_of_week(date) do
    case day_of_week(date) do
      {day_of_week, day_of_week, _last_day_of_week} ->
        0

      {day_of_week, first_day_of_week, _last_day_of_week} ->
        first_day_of_week - day_of_week -
          if day_of_week < first_day_of_week, do: @days_per_week, else: 0
    end
  end
end
