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

  def gen(%{"allOf" => options} = spec) when is_list(options) do
    option =
      options
      |> Enum.reduce(%{"properties" => %{}, "required" => []}, fn x, acc ->
        %{
          "properties" => Map.merge(acc["properties"], x |> Map.get("properties", %{})),
          "required" => (x |> Map.get("required", [])) ++ acc["required"]
        }
      end)

    spec
    |> Map.drop(["allOf"])
    |> Map.merge(option, fn
      "properties", prop1, nil -> prop1
      "properties", prop1, prop2 -> Map.merge(prop1, prop2)
      "required", prop1, prop2 -> prop1 ++ prop2
    end)
    |> Map.put("type", "object")
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

  # type not present
  def gen(spec) do
    Enum.map(@types, fn type ->
      Map.put(spec, "type", type)
      |> gen()
    end)
    |> StreamData.one_of()
  end
end
