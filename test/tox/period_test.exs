defmodule Tox.PeriodTest do
  use ExUnit.Case

  alias Tox.Period

  doctest Tox.Period
  doctest Tox.Period.Sigil

  describe "parse/1" do
    test "returns error tuple" do
      assert Period.parse("foo") == {:error, :invalid_format}
      assert Period.parse("P1.2Y") == {:error, :invalid_format}
      assert Period.parse("T1..2S") == {:error, :invalid_format}
    end
  end
end
