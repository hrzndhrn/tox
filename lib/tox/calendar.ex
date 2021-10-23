defmodule Tox.Calendar do
  @moduledoc false

  # Since the first version of Tox, Date.beginning_of_week/1 is now available in
  # Elixir. With this change was also Calendar.day_of_week/3 replaced by
  # Calendar.day_of_week4. Tox implements beginning_of_week for Date, DateTime
  # and NaiveDateTime. These implementations are using the functions of this
  # module.

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
      {calendar.day_of_week(year, month, day), 1, 7}
    end
  end

  @spec beginning_of_week(Date.t() | DateTime.t() | NaiveDateTime.t()) :: 0 | neg_integer()
  def beginning_of_week(date) do
    case day_of_week(date) do
      {day_of_week, day_of_week, _last_day_of_week} ->
        0

      {day_of_week, first_day_of_week, _last_day_of_week} ->
        -(day_of_week - first_day_of_week)
    end
  end
end
