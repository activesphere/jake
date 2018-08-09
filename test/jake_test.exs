defmodule JakeTest do
  alias ExJsonSchema.Validator

  use ExUnit.Case
  doctest Jake

  @schemas [
    %{
      "type" => "object",
      "properties" => %{
        "foo" => %{
          "type" => "string"
        }
      }
    }
  ]

  test "valid" do
    for schema <- @schemas do
      Jake.gen(schema)
      |> Enum.take(10)
      |> Enum.each(fn value ->
        assert Validator.validate(schema, value) == :ok
      end)
    end
  end
end
