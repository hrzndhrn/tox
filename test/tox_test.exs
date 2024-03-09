defmodule ToxTest do
  use ExUnit.Case

  doctest README

  describe "shift/2" do
    test "shifts a datetime" do
      datetime = DateTime.from_naive!(~N[2020-07-21 19:32:00], "Europe/Berlin")
      expected = DateTime.from_naive!(~N[2020-07-22 19:32:00], "Europe/Berlin")

      assert Tox.shift(datetime, day: 1) == expected
    end

    test "shifts a date" do
      assert Tox.shift(~D[1999-01-15], year: 1) == ~D[2000-01-15]
    end

    test "shifts a naive_datetime" do
      assert Tox.shift(~N[1999-01-15 00:00:00], year: 1, hour: 1) == ~N[2000-01-15 01:00:00]
    end

    test "shifts time" do
      assert Tox.shift(~T[00:00:00], year: 1, hour: 1) == ~T[01:00:00.000000]
    end
  end
end
