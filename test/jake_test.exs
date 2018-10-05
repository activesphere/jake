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
    },
    %{
      "type" => "object",
      "properties" => %{
        "foo" => %{
          "type" => "string"
        },
        "bar" => %{
          "type" => "string"
        },
        "baz" => %{
          "type" => "string"
        }
      },
      "required" => ["foo"]
    },
    %{
      "minimum" => 0,
      "maximum" => 100,
      "exclusiveMinimum" => true,
      "exclusiveMaximum" => true
    }
  ]

  test "valid" do
    Enum.each(@schemas, &verify/1)
  end

  test "suite" do
    for path <- [
          "draft4/type.json",
          "draft4/anyOf.json",
          "draft4/required.json",
          "draft4/allOf.json",
          "draft4/enum.json",
          "draft4/minimum.json",
          "draft4/maximum.json"
        ] do
      Path.wildcard("test_suite/tests/#{path}")
      |> Enum.map(fn path -> File.read!(path) |> Jason.decode!() end)
      |> Enum.concat()
      |> Enum.map(fn %{"schema" => schema} -> verify(schema) end)
    end
  end

  def verify(schema) do
    Jake.gen(schema)
    |> Enum.take(100)
    |> Enum.each(fn value ->
      result = Validator.validate(schema, value)

      if result != :ok do
        flunk(
          "Invalid data: \nschema: #{inspect(schema)}\ngenerated: #{inspect(value)}\nerror: #{
            inspect(result)
          }"
        )
      end
    end)
  end
end
