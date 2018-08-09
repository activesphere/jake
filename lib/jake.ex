defmodule Jake do
  @types [
    "array",
    "boolean",
    "integer",
    "null",
    "number",
    "object",
    "string"
  ]

  def gen(%{"anyOf" => options} = spec) when is_list(options) do
    Enum.map(options, fn option ->
      gen(Map.merge(Map.drop(spec, ["anyOf"]), option))
    end)
    |> StreamData.one_of()
  end

  def gen(%{"type" => type} = spec) when is_binary(type) do
    module = String.to_existing_atom("Elixir.Jake.#{String.capitalize(type)}")
    apply(module, :gen, [spec])
  end

  def gen(%{"type" => types} = spec) when is_list(types) do
    Enum.map(types, fn type ->
      gen(%{spec | "type" => type})
    end)
    |> StreamData.one_of()
  end

  # type not present
  def gen(spec) do
    Enum.map(@types, fn type ->
      Map.put(spec, "type", type)
      |> gen()
    end)
    |> StreamData.one_of()
  end
end
