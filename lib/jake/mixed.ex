defmodule Jake.Mixed do
  @types [
    "array",
    "boolean",
    "integer",
    "null",
    "number",
    "object",
    "string"
  ]

  def gen_mixed(%{"anyOf" => options} = map, schema) when is_list(options) do
    nmap = Map.drop(map, ["anyOf"])

    nlist = for(n <- options, is_map(n), do: Map.merge(nmap, n))
    for(n <- nlist, do: Map.put(schema, "map", n) |> Jake.gen_init()) |> StreamData.one_of()
  end

  def gen_mixed(%{"allOf" => options} = map, schema) when is_list(options) do
    nmap = Map.drop(map, ["allOf"])

    map =
      Enum.reduce(options, %{}, fn x, acc -> Jake.MapUtil.deep_merge(acc, x) end)
      |> Jake.MapUtil.deep_merge(nmap)

    Map.put(schema, "map", map) |> Jake.gen_init()
  end
end
