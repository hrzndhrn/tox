max_runs = if System.get_env("CI"), do: 10_000, else: 100
Application.put_env(:stream_data, :max_runs, max_runs)

tzdb = TimeZoneInfo.TimeZoneDatabase
# tzdb = Tz.TimeZoneDatabase
# tzdb = Tzdata.TimeZoneDatabase

Calendar.put_time_zone_database(tzdb)

Mix.Shell.IO.info("time zone database: #{inspect tzdb} ")

ExUnit.start(timeout: :infinity)
