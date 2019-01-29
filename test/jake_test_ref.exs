defmodule JakeTestRef do
  use ExUnitProperties
  use ExUnit.Case
  doctest Jake

  def test_generator_property(schema) do
    gen = Jake.generator(schema)

    check all a <- gen do
      assert ExJsonSchema.Validator.valid?(schema, a)
    end
  end

  property "test suite ref" do
    for path <- [
          "draft4/refExtra.json"
        ] do
      Path.wildcard("test_suite/tests/#{path}")
      |> Enum.map(fn path -> File.read!(path) |> Jason.decode!() end)
      |> Enum.concat()
      |> Enum.map(fn %{"schema" => schema} -> test_generator_property(schema) end)
    end
  end
end
