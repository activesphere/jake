defmodule Jake do
  alias Jake.MapUtil

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

  def gen(%{"allOf" => options} = spec) when is_list(options) do
    properties =
      options
      |> Enum.reduce(%{}, fn x, acc -> MapUtil.deep_merge(x, acc) end)

    spec
    |> Map.drop(["allOf"])
    |> MapUtil.deep_merge(properties)
    |> gen
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

  def gen(%{"enum" => enum}) when is_list(enum) do
    StreamData.member_of(enum)
  end

  # type not present
  def gen(spec) do
    StreamData.member_of(@types)
    |> StreamData.bind(fn type ->
      Map.put(spec, "type", type)
      |> gen()
    end)
  end
end
