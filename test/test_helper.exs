max_runs = if System.get_env("CI"), do: 10_000, else: 100
Application.put_env(:stream_data, :max_runs, max_runs)

Calendar.put_time_zone_database(TimeZoneInfo.TimeZoneDatabase)

ExUnit.start(timeout: :infinity)
